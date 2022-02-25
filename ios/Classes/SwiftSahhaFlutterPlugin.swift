import Flutter
import UIKit
import Sahha

public class SwiftSahhaFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sahha_flutter", binaryMessenger: registrar.messenger())
    let instance = SwiftSahhaFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    if call.method == "getBatteryLevel" {
receiveBatteryLevel(result: result)
    } else if call.method == "getPlatformVersion" {
          result("iOS " + UIDevice.current.systemVersion)
    } else if call.method == "getBundleId" {
        result(Sahha.shared.getBundleId())
    }
    else {
    result(FlutterMethodNotImplemented)
    return
  }
  }

  private func receiveBatteryLevel(result: FlutterResult) {
  let device = UIDevice.current
  device.isBatteryMonitoringEnabled = true
  if device.batteryState == UIDevice.BatteryState.unknown {
    result(FlutterError(code: "UNAVAILABLE",
                        message: "Battery info unavailable",
                        details: nil))
  } else {
    result("Battery level: \(device.batteryLevel * 100)%")
  }
}
}
