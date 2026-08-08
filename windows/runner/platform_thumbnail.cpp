#include "platform_thumbnail.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <propkey.h>
#include <shobjidl.h>
#include <wincodec.h>
#include <windows.h>
#include <wrl/client.h>

#include <algorithm>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace {

using Microsoft::WRL::ComPtr;

constexpr UINT kThumbnailReadyMessage = WM_APP + 0x51;

struct PendingThumbnailResult {
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
  flutter::EncodableValue value;
};

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return {};
  }
  const int length = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                         static_cast<int>(value.size()),
                                         nullptr, 0);
  std::wstring result(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(),
                      static_cast<int>(value.size()), result.data(), length);
  return result;
}

std::vector<uint8_t> EncodePng(HBITMAP bitmap) {
  ComPtr<IWICImagingFactory> factory;
  if (FAILED(CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                              CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory)))) {
    return {};
  }

  ComPtr<IWICBitmap> source;
  if (FAILED(factory->CreateBitmapFromHBITMAP(
          bitmap, nullptr, WICBitmapUsePremultipliedAlpha, &source))) {
    return {};
  }

  ComPtr<IStream> stream;
  if (FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream))) {
    return {};
  }

  ComPtr<IWICBitmapEncoder> encoder;
  if (FAILED(factory->CreateEncoder(GUID_ContainerFormatPng, nullptr,
                                    &encoder)) ||
      FAILED(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache))) {
    return {};
  }

  ComPtr<IWICBitmapFrameEncode> frame;
  if (FAILED(encoder->CreateNewFrame(&frame, nullptr)) ||
      FAILED(frame->Initialize(nullptr))) {
    return {};
  }

  UINT width = 0;
  UINT height = 0;
  if (FAILED(source->GetSize(&width, &height)) ||
      FAILED(frame->SetSize(width, height))) {
    return {};
  }
  WICPixelFormatGUID format = GUID_WICPixelFormat32bppBGRA;
  if (FAILED(frame->SetPixelFormat(&format)) ||
      FAILED(frame->WriteSource(source.Get(), nullptr)) ||
      FAILED(frame->Commit()) || FAILED(encoder->Commit())) {
    return {};
  }

  STATSTG stat = {};
  if (FAILED(stream->Stat(&stat, STATFLAG_NONAME)) ||
      stat.cbSize.QuadPart <= 0) {
    return {};
  }
  LARGE_INTEGER start = {};
  if (FAILED(stream->Seek(start, STREAM_SEEK_SET, nullptr))) {
    return {};
  }
  std::vector<uint8_t> bytes(static_cast<size_t>(stat.cbSize.QuadPart));
  ULONG bytes_read = 0;
  if (FAILED(stream->Read(bytes.data(), static_cast<ULONG>(bytes.size()),
                          &bytes_read))) {
    return {};
  }
  bytes.resize(bytes_read);
  return bytes;
}

std::vector<uint8_t> GetShellThumbnail(const std::string& path, int size) {
  ComPtr<IShellItemImageFactory> image_factory;
  const std::wstring wide_path = Utf8ToWide(path);
  if (FAILED(SHCreateItemFromParsingName(wide_path.c_str(), nullptr,
                                         IID_PPV_ARGS(&image_factory)))) {
    return {};
  }

  HBITMAP bitmap = nullptr;
  const SIZE requested_size = {size, size};
  const HRESULT result = image_factory->GetImage(
      requested_size,
      static_cast<SIIGBF>(SIIGBF_BIGGERSIZEOK | SIIGBF_THUMBNAILONLY),
      &bitmap);
  if (FAILED(result) || bitmap == nullptr) {
    return {};
  }
  const auto bytes = EncodePng(bitmap);
  DeleteObject(bitmap);
  return bytes;
}

std::optional<std::pair<uint64_t, uint64_t>> GetVideoDimensions(
    const std::string& path) {
  const HRESULT startup_result = MFStartup(MF_VERSION, MFSTARTUP_FULL);
  if (SUCCEEDED(startup_result)) {
    ComPtr<IMFSourceReader> reader;
    ComPtr<IMFMediaType> media_type;
    const std::wstring wide_path = Utf8ToWide(path);
    if (SUCCEEDED(MFCreateSourceReaderFromURL(wide_path.c_str(), nullptr,
                                              &reader)) &&
        SUCCEEDED(reader->GetNativeMediaType(
            MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, &media_type))) {
      UINT32 width = 0;
      UINT32 height = 0;
      if (SUCCEEDED(MFGetAttributeSize(media_type.Get(), MF_MT_FRAME_SIZE,
                                       &width, &height)) &&
          width > 0 && height > 0) {
        UINT32 rotation = MFVideoRotationFormat_0;
        if (SUCCEEDED(media_type->GetUINT32(MF_MT_VIDEO_ROTATION, &rotation)) &&
            (rotation == MFVideoRotationFormat_90 ||
             rotation == MFVideoRotationFormat_270)) {
          std::swap(width, height);
        }
        MFShutdown();
        return std::pair<uint64_t, uint64_t>(width, height);
      }
    }
    MFShutdown();
  }

  ComPtr<IShellItem2> shell_item;
  const std::wstring wide_path = Utf8ToWide(path);
  if (FAILED(SHCreateItemFromParsingName(wide_path.c_str(), nullptr,
                                         IID_PPV_ARGS(&shell_item)))) {
    return std::nullopt;
  }

  ULONGLONG width = 0;
  ULONGLONG height = 0;
  if (FAILED(shell_item->GetUInt64(PKEY_Video_FrameWidth, &width)) ||
      FAILED(shell_item->GetUInt64(PKEY_Video_FrameHeight, &height)) ||
      width == 0 || height == 0) {
    return std::nullopt;
  }
  UINT32 orientation = 1;
  if (SUCCEEDED(
          shell_item->GetUInt32(PKEY_Photo_Orientation, &orientation)) &&
      orientation >= 5 && orientation <= 8) {
    std::swap(width, height);
  }
  return std::pair<uint64_t, uint64_t>(width, height);
}

}  // namespace

void RegisterPlatformThumbnailChannel(flutter::BinaryMessenger* messenger,
                                      HWND window) {
  static auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "hello_gallery/platform_thumbnail",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [window](const auto& call, auto result) {
        const bool is_thumbnail = call.method_name() == "getThumbnail";
        const bool is_dimensions = call.method_name() == "getDimensions";
        if (!is_thumbnail && !is_dimensions) {
          result->NotImplemented();
          return;
        }
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments", "Expected a map of arguments");
          return;
        }
        const auto path_it = arguments->find(flutter::EncodableValue("path"));
        if (path_it == arguments->end()) {
          result->Error("invalid_arguments", "Missing path");
          return;
        }
        const auto* path = std::get_if<std::string>(&path_it->second);
        if (path == nullptr) {
          result->Error("invalid_arguments", "Invalid path");
          return;
        }
        const auto requested_path = *path;

        int requested_size = 0;
        if (is_thumbnail) {
          const auto size_it =
              arguments->find(flutter::EncodableValue("size"));
          if (size_it == arguments->end()) {
            result->Error("invalid_arguments", "Missing size");
            return;
          }
          const auto* size = std::get_if<int32_t>(&size_it->second);
          if (size == nullptr) {
            result->Error("invalid_arguments", "Invalid size");
            return;
          }
          requested_size = std::clamp(*size, 64, 1024);
        }

        std::thread([window, requested_path, requested_size, is_thumbnail,
                     result = std::move(result)]() mutable {
          const HRESULT com_result =
              CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
          flutter::EncodableValue value;
          if (is_thumbnail) {
            auto bytes = GetShellThumbnail(requested_path, requested_size);
            if (!bytes.empty()) {
              value = flutter::EncodableValue(std::move(bytes));
            }
          } else if (const auto dimensions =
                         GetVideoDimensions(requested_path)) {
            flutter::EncodableMap result_map;
            result_map[flutter::EncodableValue("width")] =
                flutter::EncodableValue(
                    static_cast<int64_t>(dimensions->first));
            result_map[flutter::EncodableValue("height")] =
                flutter::EncodableValue(
                    static_cast<int64_t>(dimensions->second));
            value = flutter::EncodableValue(std::move(result_map));
          }
          if (SUCCEEDED(com_result)) {
            CoUninitialize();
          }
          auto pending = std::make_unique<PendingThumbnailResult>();
          pending->result = std::move(result);
          pending->value = std::move(value);
          if (PostMessage(window, kThumbnailReadyMessage,
                          reinterpret_cast<WPARAM>(pending.get()), 0)) {
            pending.release();
          }
        }).detach();
      });
}

bool HandlePlatformThumbnailMessage(UINT message, WPARAM wparam) {
  if (message != kThumbnailReadyMessage) {
    return false;
  }
  std::unique_ptr<PendingThumbnailResult> pending(
      reinterpret_cast<PendingThumbnailResult*>(wparam));
  pending->result->Success(pending->value);
  return true;
}
