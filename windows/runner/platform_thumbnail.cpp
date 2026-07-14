#include "platform_thumbnail.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shobjidl.h>
#include <wincodec.h>
#include <windows.h>
#include <wrl/client.h>

#include <algorithm>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace {

using Microsoft::WRL::ComPtr;

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

}  // namespace

void RegisterPlatformThumbnailChannel(flutter::BinaryMessenger* messenger) {
  static auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "hello_gallery/platform_thumbnail",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const auto& call, auto result) {
        if (call.method_name() != "getThumbnail") {
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
        const auto size_it = arguments->find(flutter::EncodableValue("size"));
        if (path_it == arguments->end() || size_it == arguments->end()) {
          result->Error("invalid_arguments", "Missing path or size");
          return;
        }
        const auto* path = std::get_if<std::string>(&path_it->second);
        const auto* size = std::get_if<int32_t>(&size_it->second);
        if (path == nullptr || size == nullptr) {
          result->Error("invalid_arguments", "Invalid path or size");
          return;
        }
        auto bytes = GetShellThumbnail(*path, std::clamp(*size, 64, 1024));
        if (bytes.empty()) {
          result->Success();
          return;
        }
        result->Success(flutter::EncodableValue(bytes));
      });
}
