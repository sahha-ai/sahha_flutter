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
        case enableSensors
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
            getDemographic(result)
        case .postDemographic:
            postDemographic(call.arguments, result: result)
        case .getSensorStatus:
            getSensorStatus(result)
        case .enableSensors:
            enableSensors(result)
        case .postSensorData:
            postSensorData(result)
        case .analyze:
            analyze(call.arguments, result: result)
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
    
    private func getDemographic(_ result: @escaping FlutterResult) {
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
            if let ethnicity = values["ethnicity"] as? String {
                demographic.ethnicity = ethnicity
            }
            if let occupation = values["occupation"] as? String {
                demographic.occupation = occupation
            }
            if let industry = values["industry"] as? String {
                demographic.industry = industry
            }
            if let incomeRange = values["incomeRange"] as? String {
                demographic.incomeRange = incomeRange
            }
            if let education = values["education"] as? String {
                demographic.education = education
            }
            if let relationship = values["relationship"] as? String {
                demographic.relationship = relationship
            }
            if let locale = values["locale"] as? String {
                demographic.locale = locale
            }
            if let livingArrangement = values["livingArrangement"] as? String {
                demographic.livingArrangement = livingArrangement
            }
            if let birthDate = values["birthDate"] as? String {
                demographic.birthDate = birthDate
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

    private func getSensorStatus(_ result: @escaping FlutterResult) {
        Sahha.getSensorStatus { sensorStatus in
            result(sensorStatus.rawValue)
        }
    }
    
    private func enableSensors(_ result: @escaping FlutterResult) {
        Sahha.enableSensors { sensorStatus in
            result(sensorStatus.rawValue)
        }
    }
    
    private func postSensorData(_ result: @escaping FlutterResult) {
        Sahha.postSensorData { error, success in
            if let error = error {
                result(FlutterError(code: "Sahha Error", message: error, details: nil))
            } else {
                result(success)
            }
        }
    }

    private func analyze(_ params: Any?, result: @escaping FlutterResult) {
        var dates: (startDate: Date, endDate: Date)?
        var includeSourceData: Bool = false
        if let values = params as? [String: Any?] {
            if let startDateNumber = values["startDate"] as? NSNumber, let endDateNumber = values["endDate"] as? NSNumber {
                let startDate = Date(timeIntervalSince1970: TimeInterval(startDateNumber.doubleValue / 1000))
                let endDate = Date(timeIntervalSince1970: TimeInterval(endDateNumber.doubleValue / 1000))
                print("startDate", startDate.toTimezoneFormat)
                print("endDate", endDate.toTimezoneFormat)
                dates = (startDate, endDate)
                print(startDate, endDate)
            } else {
                print("no dates")
            }
            if let boolValue = values["includeSourceData"] as? Bool {
                includeSourceData = boolValue
                print("includeSourceData",includeSourceData)
            }
        }
        Sahha.analyze(dates: dates, includeSourceData: includeSourceData) { error, value in
            if let error = error {
                result(FlutterError(code: "Sahha Error", message: error, details: nil))
            } else if let value = value {
                print(value)
                result(value)
            } else {
                result(FlutterError(code: "Sahha Error", message: "Requested Sahha Analyzation not available", details: nil))
            }
        }
    }
}
