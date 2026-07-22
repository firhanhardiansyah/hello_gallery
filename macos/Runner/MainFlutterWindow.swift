import Cocoa
import FlutterMacOS
import QuickLookThumbnailing

class MainFlutterWindow: NSWindow {
  // Keep in sync with DesktopWindowTitleBar.height in Flutter.
  private static let integratedTitleBarHeight: CGFloat = 56
  // Keep in sync with DesktopWindowTitleBar.macOSWindowButtonsInset.
  private static let nativeWindowButtonsInset: CGFloat = 80
  // Positive values move the native window buttons right and down.
  private static let trafficLightHorizontalOffset: CGFloat = 6
  private static let trafficLightVerticalOffset: CGFloat = 0

  private var platformThumbnailChannel: FlutterMethodChannel?
  private var folderManagementChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerPlatformThumbnailChannel(flutterViewController)
    registerFolderManagementChannel(flutterViewController)

    super.awakeFromNib()

    observeWindowLayoutChanges()
    alignTrafficLights()
  }

  override func setIsVisible(_ flag: Bool) {
    super.setIsVisible(flag)
    if flag {
      alignTrafficLights()
    }
  }

  override func makeKeyAndOrderFront(_ sender: Any?) {
    super.makeKeyAndOrderFront(sender)
    alignTrafficLights()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func observeWindowLayoutChanges() {
    let notifications: [Notification.Name] = [
      NSWindow.didBecomeKeyNotification,
      NSWindow.didResizeNotification,
      NSWindow.didEndLiveResizeNotification,
      NSWindow.didExitFullScreenNotification,
      NSWindow.didChangeScreenNotification,
    ]
    for notification in notifications {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleWindowLayoutChange(_:)),
        name: notification,
        object: self
      )
    }
  }

  @objc private func handleWindowLayoutChange(_ notification: Notification) {
    alignTrafficLights()
  }

  private func alignTrafficLights() {
    guard
      !styleMask.contains(.fullScreen),
      let contentView
    else {
      return
    }

    contentView.layoutSubtreeIfNeeded()
    let titleBarCenterY = Self.integratedTitleBarHeight / 2
    let contentCenterY = contentView.isFlipped
      ? contentView.bounds.minY + titleBarCenterY
        + Self.trafficLightVerticalOffset
      : contentView.bounds.maxY - titleBarCenterY
        - Self.trafficLightVerticalOffset
    let targetCenterInWindow = contentView.convert(
      NSPoint(
        x: contentView.bounds.minX + Self.nativeWindowButtonsInset / 2
          + Self.trafficLightHorizontalOffset,
        y: contentCenterY
      ),
      to: nil
    )

    let buttonTypes: [NSWindow.ButtonType] = [
      .closeButton,
      .miniaturizeButton,
      .zoomButton,
    ]
    let buttons: [(button: NSButton, container: NSView)] = buttonTypes.compactMap {
      buttonType in
      guard
        let button = standardWindowButton(buttonType),
        let container = button.superview
      else {
        return nil
      }
      return (button, container)
    }
    guard !buttons.isEmpty else { return }

    let framesInWindow = buttons.map { entry in
      entry.container.convert(entry.button.frame, to: nil)
    }
    guard
      let groupMinX = framesInWindow.map({ $0.minX }).min(),
      let groupMaxX = framesInWindow.map({ $0.maxX }).max()
    else {
      return
    }
    let horizontalOffset = targetCenterInWindow.x - (groupMinX + groupMaxX) / 2

    for entry in buttons {
      let button = entry.button
      let buttonContainer = entry.container
      let centerInContainer = buttonContainer.convert(
        targetCenterInWindow,
        from: nil
      )
      button.setFrameOrigin(
        NSPoint(
          x: button.frame.origin.x + horizontalOffset,
          y: centerInContainer.y - button.frame.height / 2
        )
      )
    }
  }

  private func registerFolderManagementChannel(
    _ flutterViewController: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "hello_gallery/folder_management",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "moveToTrash" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let folderPath = arguments["path"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing or invalid folder path",
            details: nil
          )
        )
        return
      }

      NSWorkspace.shared.recycle([URL(fileURLWithPath: folderPath)]) {
        _, error in
        DispatchQueue.main.async {
          if let error {
            result(
              FlutterError(
                code: "trash_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      }
    }
    folderManagementChannel = channel
  }

  private func registerPlatformThumbnailChannel(
    _ flutterViewController: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "hello_gallery/platform_thumbnail",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getThumbnail" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let filePath = arguments["path"] as? String,
        let size = arguments["size"] as? Int
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing or invalid path or size",
            details: nil
          )
        )
        return
      }

      let requestSize = CGFloat(max(64, min(size, 1024)))
      let request = QLThumbnailGenerator.Request(
        fileAt: URL(fileURLWithPath: filePath),
        size: CGSize(width: requestSize, height: requestSize),
        scale: 1,
        representationTypes: .thumbnail
      )
      QLThumbnailGenerator.shared.generateBestRepresentation(for: request) {
        representation,
        error in
        let data = representation.flatMap { thumbnail in
          NSBitmapImageRep(cgImage: thumbnail.cgImage).representation(
            using: .jpeg,
            properties: [.compressionFactor: 0.82]
          )
        }
        DispatchQueue.main.async {
          if let data {
            result(FlutterStandardTypedData(bytes: data))
          } else if let error {
            result(
              FlutterError(
                code: "thumbnail_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          } else {
            result(nil)
          }
        }
      }
    }
    platformThumbnailChannel = channel
  }
}
