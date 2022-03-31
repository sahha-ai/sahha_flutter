import Flutter
import UIKit
import Sahha

public class SwiftSahhaFlutterPlugin: NSObject, FlutterPlugin {
    
    enum SahhaActivity: String {
        case motion
        case health
    }
    
    enum SahhaMethod: String {
        case configure
        case authenticate
        case activityStatus
        case activate
        case promptUserToActivate
        case postActivity
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
        case .configure:
            configure(call.arguments, result: result)
        case .authenticate:
            authenticate(call.arguments, result: result)
        case .activityStatus:
            activityStatus(call.arguments, result: result)
        case .activate:
            activate(call.arguments, result: result)
        case .promptUserToActivate:
            promptUserToActivate(call.arguments, result: result)
        case .postActivity:
            postActivity(call.arguments, result: result)
        case .analyze:
            analyze(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func configure(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [Any?] {
            if let environment = values[0] as? String, let configEnvironment = SahhaEnvironment(rawValue: environment), let sensors = values[1] as? [String], let postActivityManually = values[2] as? NSNumber {
                
                var configSensors: Set<SahhaSensor> = []
                for sensor in sensors {
                    if let configSensor = SahhaSensor(rawValue: sensor) {
                        configSensors.insert(configSensor)
                    }
                }

                let settings = SahhaSettings(environment: configEnvironment, sensors: configSensors, postActivityManually: postActivityManually.boolValue)
                Sahha.configure(settings)
                
                // Needed by Flutter since native iOS lifecycle is delayed
                Sahha.launch()
            } else {
                result(FlutterError(code: "Sahha Error", message: "SahhaFlutter.configure() paramaters are not valid", details: nil))
            }
        }
        else {
            result(FlutterError(code: "Sahha Error", message: "SahhaFlutter.configure() paramaters are missing", details: nil))
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
                    result(FlutterError(code: "Sahha Error", message: "Sahha was unable to authenticate", details: nil))
                }
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Something went wrong", details: nil))
        }
    }
    
    private func activityStatus(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [Any?], let activityString = values[0] as? String, let activity = SahhaActivity(rawValue: activityString) {
            switch activity {
            case .motion:
                result(Sahha.motion.activityStatus.rawValue)
            case .health:
                result(Sahha.health.activityStatus.rawValue)
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Requested Sahha Activity not found", details: nil))
        }
    }
    
    private func activate(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [Any?], let activityString = values[0] as? String, let activity = SahhaActivity(rawValue: activityString) {
            switch activity {
            case .motion:
                Sahha.motion.activate { activityStatus in
                    result(activityStatus.rawValue)
                }
            case .health:
                Sahha.health.activate { activityStatus in
                    result(activityStatus.rawValue)
                }
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Requested Sahha Activity not found", details: nil))
        }
    }
    
    private func promptUserToActivate(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [Any?], let activityString = values[0] as? String, let activity = SahhaActivity(rawValue: activityString) {
            switch activity {
            case .motion:
                Sahha.motion.promptUserToActivate { activityStatus in
                    result(activityStatus.rawValue)
                }
            case .health:
                Sahha.health.activate { activityStatus in
                    result(activityStatus.rawValue)
                }
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Requested Sahha Activity not found", details: nil))
        }
    }
    
    private func postActivity(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [Any?], let activityString = values[0] as? String, let activity = SahhaActivity(rawValue: activityString) {
            switch activity {
            case .motion:
                Sahha.motion.postActivity { error, success in
                    if let error = error {
                        result(FlutterError(code: "Sahha Error", message: error, details: nil))
                    } else {
                        result(success)
                    }
                }
            case .health:
                Sahha.health.postActivity { error, success in
                    if let error = error {
                        result(FlutterError(code: "Sahha Error", message: error, details: nil))
                    } else {
                        result(success)
                    }
                }
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Requested Sahha Activity not found", details: nil))
        }
    }
    
    private func analyze(result: @escaping FlutterResult) {
        Sahha.analyze { error, value in
            if let error = error {
                result(FlutterError(code: "Sahha Error", message: error, details: nil))
            } else if let value = value {
                result(value)
            } else {
                result(FlutterError(code: "Sahha Error", message: "Requested Sahha Analyzation not available", details: nil))
            }
        }
    }
}
