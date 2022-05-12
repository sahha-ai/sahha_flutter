import Flutter
import Sahha
import UIKit

public class SwiftSahhaFlutterPlugin: NSObject, FlutterPlugin {
    enum SahhaActivity: String {
        case motion
        case health
    }

    enum SahhaMethod: String {
        case configure
        case authenticate
        case getDemographic
        case postDemographic
        case getSensorStatus
        case enableSensor
        case postSensorData
        case analyze
        case openAppSettings
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
        case .getDemographic:
            getDemographic(result: result)
        case .postDemographic:
            postDemographic(call.arguments, result: result)
        case .getSensorStatus:
            getSensorStatus(call.arguments, result: result)
        case .enableSensor:
            enableSensor(call.arguments, result: result)
        case .postSensorData:
            postSensorData(call.arguments, result: result)
        case .analyze:
            analyze(result: result)
        case .openAppSettings:
            Sahha.openAppSettings()
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func configure(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let environment = values["environment"] as? String, let configEnvironment = SahhaEnvironment(rawValue: environment), let sensors = values["sensors"] as? [String], let postSensorDataManually = values["postSensorDataManually"] as? NSNumber {
            var configSensors: Set<SahhaSensor> = []
            for sensor in sensors {
                if let configSensor = SahhaSensor(rawValue: sensor) {
                    configSensors.insert(configSensor)
                }
            }

            var settings = SahhaSettings(environment: configEnvironment, sensors: configSensors, postSensorDataManually: postSensorDataManually.boolValue)
            settings.framework = .flutter
            Sahha.configure(settings)

            // Needed by Flutter since native iOS lifecycle is delayed
            Sahha.launch()

            result(true)
        } else {
            result(FlutterError(code: "Sahha Error", message: "SahhaFlutter.configure() parameters are not valid", details: nil))
        }
    }

    private func authenticate(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let profileToken = values["profileToken"] as? String, let refreshToken = values["refreshToken"] as? String {
            let success = Sahha.authenticate(profileToken: profileToken, refreshToken: refreshToken)
            result(success)
        } else {
            result(FlutterError(code: "Sahha Error", message: "SahhaFlutter.authenticate() parameters are not valid", details: nil))
        }
    }
    
    private func getDemographic(result: @escaping FlutterResult) {
        Sahha.getDemographic { error, value in
            if let error = error {
                result(FlutterError(code: "Sahha Error", message: error, details: nil))
            } else if let value = value {
                do {
                    let jsonEncoder = JSONEncoder()
                    jsonEncoder.outputFormatting = .prettyPrinted
                    let jsonData = try jsonEncoder.encode(value)
                    let string = String(data: jsonData, encoding: .utf8)
                    result(string)
                } catch let encodingError {
                    print(encodingError)
                    result(FlutterError(code: "Sahha Error", message: "Requested Sahha Demographic decoding error", details: nil))
                }
            } else {
                result(FlutterError(code: "Sahha Error", message: "Requested Sahha Demographic not available", details: nil))
            }
        }
    }

    private func postDemographic(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?] {
            var demographic = SahhaDemographic()
            if let ageNumber = values["age"] as? NSNumber {
                let age = ageNumber.intValue
                demographic.age = age
            }
            if let gender = values["gender"] as? String {
                demographic.gender = gender
            }
            if let country = values["country"] as? String {
                demographic.country = country
            }
            if let birthCountry = values["birthCountry"] as? String {
                demographic.birthCountry = birthCountry
            }
            Sahha.postDemographic(demographic) { error, success in
                if let error = error {
                    result(FlutterError(code: "Sahha Error", message: error, details: nil))
                } else {
                    result(success)
                }
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Sahha demographic parameters are missing", details: nil))
        }
    }

    private func getSensorStatus(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let sensorString = values["sensor"] as? String, let sensor = SahhaSensor(rawValue: sensorString) {
            Sahha.getSensorStatus(sensor) { sensorStatus in
                result(sensorStatus.rawValue)
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Sahha Sensor parameter is not valid", details: nil))
        }
    }

    private func enableSensor(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let sensorString = values["sensor"] as? String, let sensor = SahhaSensor(rawValue: sensorString) {
            Sahha.enableSensor(sensor) { sensorStatus in
                result(sensorStatus.rawValue)
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Sahha Sensor parameter is not valid", details: nil))
        }
    }

    private func postSensorData(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let sensors = values["sensors"] as? [String] {
            var sahhaSensors: Set<SahhaSensor> = []
            for sensor in sensors {
                if let sahhaSensor = SahhaSensor(rawValue: sensor) {
                    sahhaSensors.insert(sahhaSensor)
                } else {
                    result(FlutterError(code: "Sahha Error", message: "\(sensor) is not a valid Sahha Sensor", details: nil))
                    return
                }
            }
            if sahhaSensors.isEmpty {
                result(FlutterError(code: "Sahha Error", message: "Sahha Sensors parameter is empty", details: nil))
            } else {
                Sahha.postSensorData(sahhaSensors) { error, success in
                    if let error = error {
                        result(FlutterError(code: "Sahha Error", message: error, details: nil))
                    } else {
                        result(success)
                    }
                }
            }
        } else {
            result(FlutterError(code: "Sahha Error", message: "Sahha Sensors parameter is missing", details: nil))
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
