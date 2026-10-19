import UIKit
import Flutter
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Replay files opened with Podium, copied out of the inbox, until Dart takes them.
  private var pendingReplayImports: [String] = []
  private var replayImportChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerReplayImportChannel()

    // Replay files arrive through application(_:open:options:) after launch.
    if let url = launchOptions?[.url] as? URL, url.isFileURL {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Retrieve the link from parameters
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      // We have a link, propagate it to your Flutter app
      AppLinks.shared.handleLink(url: url)
      return true // Returning true will stop the propagation to other packages
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.isFileURL && url.pathExtension.lowercased() == "podium" {
      importReplay(from: url)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  private func registerReplayImportChannel() {
    guard let registrar = registrar(forPlugin: "PodiumReplayImport") else { return }
    let channel = FlutterMethodChannel(
      name: "podium/replay_import",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takePendingImports" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.pendingReplayImports ?? [])
      self?.pendingReplayImports.removeAll()
    }
    replayImportChannel = channel
  }

  private func importReplay(from url: URL) {
    DispatchQueue.global(qos: .userInitiated).async {
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("replay_imports", isDirectory: true)
      let target = dir.appendingPathComponent(
        "import_\(Int(Date().timeIntervalSince1970 * 1000)).podium")
      do {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: url, to: target)
        // Files handed over through the inbox are ours to delete.
        if url.path.contains("/Inbox/") { try? FileManager.default.removeItem(at: url) }
      } catch {
        NSLog("Podium: could not copy replay \(url): \(error)")
        return
      }
      DispatchQueue.main.async {
        self.pendingReplayImports.append(target.path)
        self.replayImportChannel?.invokeMethod("replayImportAvailable", arguments: nil)
      }
    }
  }
}
