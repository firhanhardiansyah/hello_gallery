#include "platform_folder_management.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <windows.h>

#include <memory>
#include <string>
#include <thread>

namespace {

constexpr UINT kFolderTrashReadyMessage = WM_APP + 0x52;

struct PendingTrashResult {
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
  int error_code = 0;
  bool aborted = false;
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

PendingTrashResult MoveToRecycleBin(HWND window, const std::string& path) {
  std::wstring source = Utf8ToWide(path);
  source.push_back(L'\0');

  SHFILEOPSTRUCTW operation = {};
  operation.hwnd = window;
  operation.wFunc = FO_DELETE;
  operation.pFrom = source.c_str();
  operation.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_NOERRORUI |
                     FOF_SILENT;

  PendingTrashResult pending;
  pending.error_code = SHFileOperationW(&operation);
  pending.aborted = operation.fAnyOperationsAborted == TRUE;
  return pending;
}

}  // namespace

void RegisterPlatformFolderManagementChannel(
    flutter::BinaryMessenger* messenger,
    HWND window) {
  static auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "hello_gallery/folder_management",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([window](const auto& call, auto result) {
    if (call.method_name() != "moveToTrash") {
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
      result->Error("invalid_arguments", "Missing file system path");
      return;
    }
    const auto* path = std::get_if<std::string>(&path_it->second);
    if (path == nullptr || path->empty()) {
      result->Error("invalid_arguments", "Invalid folder path");
      return;
    }

    const auto requested_path = *path;
    std::thread([window, requested_path, result = std::move(result)]() mutable {
      const HRESULT com_result =
          CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
      auto pending = std::make_unique<PendingTrashResult>(
          MoveToRecycleBin(window, requested_path));
      if (SUCCEEDED(com_result)) {
        CoUninitialize();
      }
      pending->result = std::move(result);
      if (PostMessage(window, kFolderTrashReadyMessage,
                      reinterpret_cast<WPARAM>(pending.get()), 0)) {
        pending.release();
      }
    }).detach();
  });
}

bool HandlePlatformFolderManagementMessage(UINT message, WPARAM wparam) {
  if (message != kFolderTrashReadyMessage) {
    return false;
  }
  std::unique_ptr<PendingTrashResult> pending(
      reinterpret_cast<PendingTrashResult*>(wparam));
  if (pending->error_code == 0 && !pending->aborted) {
    pending->result->Success();
  } else {
    pending->result->Error(
        "trash_failed", "Could not move item to Recycle Bin",
        flutter::EncodableValue(pending->error_code));
  }
  return true;
}
