import Cocoa
import AVFoundation
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
        let entityPath = arguments["path"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing or invalid file system path",
            details: nil
          )
        )
        return
      }

      NSWorkspace.shared.recycle([URL(fileURLWithPath: entityPath)]) {
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
      guard
        call.method == "getThumbnail" || call.method == "getDimensions"
          || call.method == "getFrame"
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let filePath = arguments["path"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing or invalid path",
            details: nil
          )
        )
        return
      }

      if call.method == "getDimensions" {
        self.readVideoDimensions(at: filePath, result: result)
        return
      }

      guard let size = arguments["size"] as? Int else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing or invalid size",
            details: nil
          )
        )
        return
      }

      if call.method == "getFrame" {
        guard let timestampMs = arguments["timestampMs"] as? Int else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "Missing or invalid timestampMs",
              details: nil
            )
          )
          return
        }
        self.readVideoFrame(
          at: filePath,
          timestampMs: max(0, timestampMs),
          maximumSize: max(120, min(size, 480)),
          precise: arguments["precise"] as? Bool ?? false,
          result: result
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

  private func readVideoFrame(
    at filePath: String,
    timestampMs: Int,
    maximumSize: Int,
    precise: Bool,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let asset = AVURLAsset(url: URL(fileURLWithPath: filePath))
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      let targetSize = CGFloat(maximumSize)
      generator.maximumSize = CGSize(width: targetSize, height: targetSize)
      let tolerance = precise
        ? CMTime.zero
        : CMTime(value: 500, timescale: 1000)
      generator.requestedTimeToleranceBefore = tolerance
      generator.requestedTimeToleranceAfter = tolerance
      let requestedTime = CMTime(value: CMTimeValue(timestampMs), timescale: 1000)

      do {
        let image = try generator.copyCGImage(at: requestedTime, actualTime: nil)
        let data = NSBitmapImageRep(cgImage: image).representation(
          using: .jpeg,
          properties: [.compressionFactor: 0.72]
        )
        DispatchQueue.main.async {
          if let data {
            result(FlutterStandardTypedData(bytes: data))
          } else {
            result(nil)
          }
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "frame_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }

  private func readVideoDimensions(
    at filePath: String,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.global(qos: .utility).async {
      let asset = AVURLAsset(url: URL(fileURLWithPath: filePath))
      guard let track = asset.tracks(withMediaType: .video).first else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      let transformedSize = track.naturalSize.applying(track.preferredTransform)
      let width = Int(abs(transformedSize.width).rounded())
      let height = Int(abs(transformedSize.height).rounded())
      DispatchQueue.main.async {
        guard width > 0, height > 0 else {
          result(nil)
          return
        }
        result(["width": width, "height": height])
      }
    }
  }
}
