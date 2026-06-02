import Flutter
import UIKit

// Classic Flutter iOS embedding (compatible with Flutter 3.19, which CI
// builds with). The newer scene-based embedding —
// FlutterImplicitEngineDelegate / FlutterSceneDelegate — only exists in
// Flutter 3.27+, so we don't use it here. FlutterAppDelegate remains the
// supported base class across all current Flutter versions.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
