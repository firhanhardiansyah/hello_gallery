import Cocoa
import FlutterMacOS
import QuickLookThumbnailing

class MainFlutterWindow: NSWindow {
  private var platformThumbnailChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerPlatformThumbnailChannel(flutterViewController)

    super.awakeFromNib()
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
