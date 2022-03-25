import Flutter
import UIKit
import Sahha

public class SwiftSahhaFlutterPlugin: NSObject, FlutterPlugin {
    
    enum SahhaMethod: String {
        case getBatteryLevel
        case getPlatformVersion
        case getBundleId
        case authenticate
        case analyze
    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sahha_flutter", binaryMessenger: registrar.messenger())
    let instance = SwiftSahhaFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let method = SahhaMethod(rawValue: call.method)
      
      switch method {
      case .getBatteryLevel:
          receiveBatteryLevel(result: result)
      case .getPlatformVersion:
          result("iOS " + UIDevice.current.systemVersion)
      case .getBundleId:
          result(Sahha.bundleId)
      case .authenticate:
          authenticate(call.arguments, result: result)
      case .analyze:
          analyze(result: result)
      default:
          result(FlutterMethodNotImplemented)
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
    
    private func authenticate(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [Any?], let customerId = values[0] as? String, let profileId = values[1] as? String {
            Sahha.authenticate(customerId: customerId, profileId: profileId) { error, value in
                if let error = error {
                    result(FlutterError(code: "Sahha Error", message: error, details: nil))
                } else if let value = value {
                    result(value)
                } else {
                    result(FlutterError(code: "Sahha Error", message: "Something went wrong", details: nil))
                }
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Something went wrong", details: nil))
        }
    }
    
    private func analyze(result: @escaping FlutterResult) {
        Sahha.analyze { value in
            result(value)
        }
    }
}
