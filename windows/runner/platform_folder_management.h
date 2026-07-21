#ifndef RUNNER_PLATFORM_FOLDER_MANAGEMENT_H_
#define RUNNER_PLATFORM_FOLDER_MANAGEMENT_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

void RegisterPlatformFolderManagementChannel(
    flutter::BinaryMessenger* messenger,
    HWND window);

bool HandlePlatformFolderManagementMessage(UINT message, WPARAM wparam);

#endif  // RUNNER_PLATFORM_FOLDER_MANAGEMENT_H_
