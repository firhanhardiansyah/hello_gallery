#include "platform_thumbnail.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <propkey.h>
#include <propvarutil.h>
#include <shobjidl.h>
#include <wincodec.h>
#include <windows.h>
#include <wrl/client.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
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

std::vector<uint8_t> EncodeJpeg(IWICImagingFactory* factory,
                                IWICBitmapSource* source) {
  ComPtr<IWICFormatConverter> converter;
  if (FAILED(factory->CreateFormatConverter(&converter)) ||
      FAILED(converter->Initialize(
          source, GUID_WICPixelFormat24bppBGR, WICBitmapDitherTypeNone, nullptr,
          0.0, WICBitmapPaletteTypeCustom))) {
    return {};
  }

  ComPtr<IStream> stream;
  if (FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream))) {
    return {};
  }
  ComPtr<IWICBitmapEncoder> encoder;
  if (FAILED(factory->CreateEncoder(GUID_ContainerFormatJpeg, nullptr,
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
  if (FAILED(converter->GetSize(&width, &height)) ||
      FAILED(frame->SetSize(width, height))) {
    return {};
  }
  WICPixelFormatGUID format = GUID_WICPixelFormat24bppBGR;
  if (FAILED(frame->SetPixelFormat(&format)) ||
      FAILED(frame->WriteSource(converter.Get(), nullptr)) ||
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

std::vector<uint8_t> GetVideoFrame(const std::string& path,
                                   int64_t timestamp_ms, int maximum_size,
                                   bool precise) {
  if (FAILED(MFStartup(MF_VERSION, MFSTARTUP_FULL))) {
    return {};
  }

  std::vector<uint8_t> encoded;
  do {
    ComPtr<IMFAttributes> attributes;
    if (FAILED(MFCreateAttributes(&attributes, 3))) {
      break;
    }
    attributes->SetUINT32(MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, TRUE);
    attributes->SetUINT32(MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING,
                          TRUE);
    attributes->SetUINT32(MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS, TRUE);

    ComPtr<IMFSourceReader> reader;
    const std::wstring wide_path = Utf8ToWide(path);
    if (FAILED(MFCreateSourceReaderFromURL(wide_path.c_str(), attributes.Get(),
                                           &reader))) {
      break;
    }
    constexpr DWORD video_stream =
        static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM);
    ComPtr<IMFMediaType> native_type;
    if (FAILED(reader->GetNativeMediaType(video_stream, 0, &native_type))) {
      break;
    }
    UINT32 width = 0;
    UINT32 height = 0;
    if (FAILED(MFGetAttributeSize(native_type.Get(), MF_MT_FRAME_SIZE, &width,
                                  &height)) ||
        width == 0 || height == 0) {
      break;
    }
    UINT32 rotation = static_cast<UINT32>(MFVideoRotationFormat_0);
    native_type->GetUINT32(MF_MT_VIDEO_ROTATION, &rotation);

    ComPtr<IMFMediaType> output_type;
    if (FAILED(MFCreateMediaType(&output_type)) ||
        FAILED(output_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video)) ||
        FAILED(output_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32)) ||
        FAILED(reader->SetCurrentMediaType(video_stream, nullptr,
                                           output_type.Get()))) {
      break;
    }
    reader->SetStreamSelection(video_stream, TRUE);

    PROPVARIANT seek_position;
    PropVariantInit(&seek_position);
    seek_position.vt = VT_I8;
    seek_position.hVal.QuadPart = std::max<int64_t>(0, timestamp_ms) * 10000;
    const HRESULT seek_result =
        reader->SetCurrentPosition(GUID_NULL, seek_position);
    PropVariantClear(&seek_position);
    if (FAILED(seek_result)) {
      break;
    }

    const LONGLONG target_timestamp =
        std::max<int64_t>(0, timestamp_ms) * 10000;
    ComPtr<IMFSample> sample;
    const int maximum_attempts = precise ? 180 : 24;
    for (int attempt = 0; attempt < maximum_attempts; ++attempt) {
      DWORD stream_flags = 0;
      LONGLONG sample_timestamp = 0;
      ComPtr<IMFSample> candidate;
      if (FAILED(reader->ReadSample(video_stream, 0, nullptr, &stream_flags,
                                    &sample_timestamp, &candidate)) ||
          (stream_flags &
           static_cast<DWORD>(MF_SOURCE_READERF_ENDOFSTREAM)) != 0) {
        break;
      }
      if (candidate != nullptr &&
          (!precise || sample_timestamp >= target_timestamp)) {
        sample = std::move(candidate);
        break;
      }
    }
    if (sample == nullptr) {
      break;
    }

    ComPtr<IMFMediaBuffer> media_buffer;
    if (FAILED(sample->ConvertToContiguousBuffer(&media_buffer))) {
      break;
    }
    const UINT stride = width * 4;
    const size_t pixel_count = static_cast<size_t>(stride) * height;
    std::vector<uint8_t> pixels(pixel_count);

    ComPtr<IMF2DBuffer> buffer_2d;
    if (SUCCEEDED(media_buffer.As(&buffer_2d))) {
      BYTE* scanline = nullptr;
      LONG pitch = 0;
      if (FAILED(buffer_2d->Lock2D(&scanline, &pitch))) {
        break;
      }
      for (UINT y = 0; y < height; ++y) {
        const BYTE* source_row =
            scanline + (static_cast<ptrdiff_t>(y) * pitch);
        std::memcpy(pixels.data() + (static_cast<size_t>(y) * stride),
                    source_row, stride);
      }
      buffer_2d->Unlock2D();
    } else {
      BYTE* data = nullptr;
      DWORD maximum_length = 0;
      DWORD current_length = 0;
      if (FAILED(media_buffer->Lock(&data, &maximum_length, &current_length))) {
        break;
      }
      const size_t copy_length =
          std::min(pixel_count, static_cast<size_t>(current_length));
      std::memcpy(pixels.data(), data, copy_length);
      media_buffer->Unlock();
      if (copy_length < pixel_count) {
        break;
      }
    }

    ComPtr<IWICImagingFactory> factory;
    if (FAILED(CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                                CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&factory)))) {
      break;
    }
    ComPtr<IWICBitmap> bitmap;
    if (FAILED(factory->CreateBitmapFromMemory(
            width, height, GUID_WICPixelFormat32bppBGR, stride,
            static_cast<UINT>(pixels.size()), pixels.data(), &bitmap))) {
      break;
    }
    ComPtr<IWICBitmapSource> source;
    bitmap.As(&source);

    ComPtr<IWICBitmapFlipRotator> rotator;
    if (rotation == static_cast<UINT32>(MFVideoRotationFormat_90) ||
        rotation == static_cast<UINT32>(MFVideoRotationFormat_180) ||
        rotation == static_cast<UINT32>(MFVideoRotationFormat_270)) {
      WICBitmapTransformOptions transform = WICBitmapTransformRotate0;
      if (rotation == static_cast<UINT32>(MFVideoRotationFormat_90)) {
        transform = WICBitmapTransformRotate90;
      } else if (rotation == static_cast<UINT32>(MFVideoRotationFormat_180)) {
        transform = WICBitmapTransformRotate180;
      } else {
        transform = WICBitmapTransformRotate270;
      }
      if (SUCCEEDED(factory->CreateBitmapFlipRotator(&rotator)) &&
          SUCCEEDED(rotator->Initialize(source.Get(), transform))) {
        rotator.As(&source);
      }
    }

    UINT oriented_width = 0;
    UINT oriented_height = 0;
    if (FAILED(source->GetSize(&oriented_width, &oriented_height)) ||
        oriented_width == 0 || oriented_height == 0) {
      break;
    }
    const double scale = std::min(
        1.0, static_cast<double>(maximum_size) /
                 static_cast<double>(std::max(oriented_width, oriented_height)));
    const UINT target_width = std::max<UINT>(
        1, static_cast<UINT>(std::lround(oriented_width * scale)));
    const UINT target_height = std::max<UINT>(
        1, static_cast<UINT>(std::lround(oriented_height * scale)));
    ComPtr<IWICBitmapScaler> scaler;
    if ((target_width != oriented_width || target_height != oriented_height) &&
        SUCCEEDED(factory->CreateBitmapScaler(&scaler)) &&
        SUCCEEDED(scaler->Initialize(source.Get(), target_width, target_height,
                                     WICBitmapInterpolationModeFant))) {
      scaler.As(&source);
    }
    encoded = EncodeJpeg(factory.Get(), source.Get());
  } while (false);

  MFShutdown();
  return encoded;
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
            static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), 0,
            &media_type))) {
      UINT32 width = 0;
      UINT32 height = 0;
      if (SUCCEEDED(MFGetAttributeSize(media_type.Get(), MF_MT_FRAME_SIZE,
                                       &width, &height)) &&
          width > 0 && height > 0) {
        UINT32 rotation = static_cast<UINT32>(MFVideoRotationFormat_0);
        if (SUCCEEDED(media_type->GetUINT32(MF_MT_VIDEO_ROTATION, &rotation)) &&
            (rotation == static_cast<UINT32>(MFVideoRotationFormat_90) ||
             rotation == static_cast<UINT32>(MFVideoRotationFormat_270))) {
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
  ULONG orientation = 1;
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
        const bool is_frame = call.method_name() == "getFrame";
        if (!is_thumbnail && !is_dimensions && !is_frame) {
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
        if (is_thumbnail || is_frame) {
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
          requested_size = std::clamp(*size, is_frame ? 120 : 64,
                                      is_frame ? 480 : 1024);
        }

        int64_t timestamp_ms = 0;
        bool precise = false;
        if (is_frame) {
          const auto timestamp_it =
              arguments->find(flutter::EncodableValue("timestampMs"));
          if (timestamp_it == arguments->end()) {
            result->Error("invalid_arguments", "Missing timestampMs");
            return;
          }
          if (const auto* timestamp_64 =
                  std::get_if<int64_t>(&timestamp_it->second)) {
            timestamp_ms = std::max<int64_t>(0, *timestamp_64);
          } else if (const auto* timestamp_32 =
                         std::get_if<int32_t>(&timestamp_it->second)) {
            timestamp_ms = std::max<int64_t>(0, *timestamp_32);
          } else {
            result->Error("invalid_arguments", "Invalid timestampMs");
            return;
          }
          const auto precise_it =
              arguments->find(flutter::EncodableValue("precise"));
          if (precise_it != arguments->end()) {
            const auto* precise_value =
                std::get_if<bool>(&precise_it->second);
            if (precise_value == nullptr) {
              result->Error("invalid_arguments", "Invalid precise value");
              return;
            }
            precise = *precise_value;
          }
        }

        std::thread([window, requested_path, requested_size, timestamp_ms,
                     precise, is_thumbnail, is_frame,
                     result = std::move(result)]() mutable {
          const HRESULT com_result =
              CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
          flutter::EncodableValue value;
          if (is_thumbnail) {
            auto bytes = GetShellThumbnail(requested_path, requested_size);
            if (!bytes.empty()) {
              value = flutter::EncodableValue(std::move(bytes));
            }
          } else if (is_frame) {
            auto bytes = GetVideoFrame(requested_path, timestamp_ms,
                                       requested_size, precise);
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
