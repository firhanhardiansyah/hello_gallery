#ifndef RUNNER_PLATFORM_THUMBNAIL_H_
#define RUNNER_PLATFORM_THUMBNAIL_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

void RegisterPlatformThumbnailChannel(flutter::BinaryMessenger* messenger,
                                      HWND window);

bool HandlePlatformThumbnailMessage(UINT message, WPARAM wparam);

#endif  // RUNNER_PLATFORM_THUMBNAIL_H_
