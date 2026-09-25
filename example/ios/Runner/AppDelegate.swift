import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    #if DEBUG
    // Sabotage channel for the Stress Lab screen. Debug builds only, and never
    // part of the plugin — see ChaosChannel.swift.
    if let registrar = registrar(forPlugin: "ChaosChannel") {
      ChaosChannel.register(messenger: registrar.messenger())
    }
    #endif

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
