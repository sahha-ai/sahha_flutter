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
        case isAuthenticated
        case authenticate
        case authenticateToken
        case deauthenticate
        case getProfileToken
        case getDemographic
        case postDemographic
        case getSensorStatus
        case enableSensors
        case getScores
        case getBiomarkers
        case getStats
        case getSamples
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
        case .isAuthenticated:
            isAuthenticated(result: result)
        case .authenticate, .authenticateToken:
            authenticate(call.arguments, result: result)
        case .deauthenticate:
            deauthenticate(result)
        case .getProfileToken:
            getProfileToken(result)
        case .getDemographic:
            getDemographic(result)
        case .postDemographic:
            postDemographic(call.arguments, result: result)
        case .getSensorStatus:
            getSensorStatus(call.arguments, result: result)
        case .enableSensors:
            enableSensors(call.arguments, result: result)
        case .getScores:
            getScores(call.arguments, result: result)
        case .getBiomarkers:
            getBiomarkers(call.arguments, result: result)
        case .getStats:
            getStats(call.arguments, result: result)
        case .getSamples:
            getSamples(call.arguments, result: result)
        case .openAppSettings:
            Sahha.openAppSettings()
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func configure(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let environment = values["environment"] as? String, let configEnvironment = SahhaEnvironment(rawValue: environment) {
            
            var settings = SahhaSettings(environment: configEnvironment)
            settings.framework = .flutter
            
            Sahha.configure(settings) {
                print("Sahha | Flutter configured")
                result(true)
            }
            
        } else {
            let message = "SahhaFlutter.configure() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "configure", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func isAuthenticated(result: @escaping FlutterResult) {
        result(Sahha.isAuthenticated)
    }
    
    private func authenticate(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?] {
            
            if let appId = values["appId"] as? String, let appSecret = values["appSecret"] as? String, let externalId = values["externalId"] as? String {
                
                Sahha.authenticate(appId: appId, appSecret: appSecret, externalId: externalId) { error, success in
                    if let error = error {
                        result(FlutterError(code: "Sahha Error", message: error, details: nil))
                    } else if success {
                        result(success)
                    }
                }
            } else if let profileToken = values["profileToken"] as? String, let refreshToken = values["refreshToken"] as? String {
                
                Sahha.authenticate(profileToken: profileToken, refreshToken: refreshToken) { error, success in
                    if let error = error {
                        result(FlutterError(code: "Sahha Error", message: error, details: nil))
                    } else if success {
                        result(success)
                    }
                }
            } else {
                let message = "SahhaFlutter.authenticate() parameters are missing"
                Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "authenticate", body: "hidden")
                result(FlutterError(code: "Sahha Error", message: message, details: nil))
            }
        } else {
            let message = "SahhaFlutter.authenticate() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "authenticate", body: "hidden")
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func deauthenticate(_ result: @escaping FlutterResult) {
        Sahha.deauthenticate { error, success in
            if let error = error {
                result(FlutterError(code: "Sahha Error", message: error, details: nil))
            } else {
                result(success)
            }
        }
    }
    
    private func getProfileToken(_ result: @escaping FlutterResult) {
        result(Sahha.profileToken)
    }
    
    private func getDemographic(_ result: @escaping FlutterResult) {
        Sahha.getDemographic { error, value in
            let body: String = value.debugDescription
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
                    Sahha.postError(framework: .flutter, message: encodingError.localizedDescription, path: "SwiftSahhaFlutterPlugin", method: "getDemographic", body: body)
                    result(FlutterError(code: "Sahha Error", message: encodingError.localizedDescription, details: nil))
                }
            } else {
                let message: String = "Requested Sahha Demographic not available"
                Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getDemographic", body: body)
                result(FlutterError(code: "Sahha Error", message: message, details: nil))
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
            let message: String = "Sahha demographic parameters are missing"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "postDemographic", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func getSensorStatus(_ params: Any?, result: @escaping FlutterResult) {
        
        if let values = params as? [String: Any?], let sensors = values["sensors"] as? [String] {
            
            var configSensors: Set<SahhaSensor> = []
            
            for sensor in sensors {
                if let configSensor = SahhaSensor(rawValue: sensor) {
                    configSensors.insert(configSensor)
                }
            }
            
            Sahha.getSensorStatus(configSensors) { error, sensorStatus in
                if let error = error {
                    result(FlutterError(code: "Sahha Error", message: error, details: nil))
                } else {
                    result(sensorStatus.rawValue)
                }
            }
            
        } else {
            let message = "SahhaFlutter.getSensorStatus() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getSensorStatus", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func enableSensors(_ params: Any?, result: @escaping FlutterResult) {
        
        if let values = params as? [String: Any?], let sensors = values["sensors"] as? [String] {
            
            var configSensors: Set<SahhaSensor> = []
            
            for sensor in sensors {
                if let configSensor = SahhaSensor(rawValue: sensor) {
                    configSensors.insert(configSensor)
                }
            }
            
            Sahha.enableSensors(configSensors) { error, sensorStatus in
                if let error = error {
                    result(FlutterError(code: "Sahha Error", message: error, details: nil))
                } else {
                    result(sensorStatus.rawValue)
                }
            }
            
        } else {
            let message = "SahhaFlutter.enableSensors() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "enableSensors", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func getScores(_ params: Any?, result: @escaping FlutterResult) {
        Sahha.postError(framework: .flutter, message: "TEST", path: "SwiftSahhaFlutterPlugin", method: "getScores", body: params.debugDescription)
        
        var scoreTypes: Set<SahhaScoreType> = []
        if let values = params as? [String: Any?], let types = values["types"] as? [String], let startDateNumber = values["startDate"] as? NSNumber, let endDateNumber = values["endDate"] as? NSNumber {
            
            let startDate = Date(timeIntervalSince1970: TimeInterval(startDateNumber.doubleValue / 1000))
            let endDate = Date(timeIntervalSince1970: TimeInterval(endDateNumber.doubleValue / 1000))
            
            for type in types {
                if let scoreType = SahhaScoreType(rawValue: type) {
                    scoreTypes.insert(scoreType)
                }
            }
            
            Sahha.getScores(types: scoreTypes, startDate: startDate, endDate: endDate) { error, value in
                if let error = error {
                    result(FlutterError(code: "Sahha Error", message: error, details: nil))
                } else if let value = value {
                    result(value)
                } else {
                    let message: String = "Requested Sahha Scores not available"
                    Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getScores", body: params.debugDescription)
                    result(FlutterError(code: "Sahha Error", message: message, details: nil))
                }
            }
        } else {
            let message = "SahhaFlutter.getScores() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getScores", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func getBiomarkers(_ params: Any?, result: @escaping FlutterResult) {
        var biomarkerCategories: Set<SahhaBiomarkerCategory> = []
        var biomarkerTypes: Set<SahhaBiomarkerType> = []
        if let values = params as? [String: Any?], let categories = values["categories"] as? [String], let types = values["types"] as? [String], let startDateNumber = values["startDate"] as? NSNumber, let endDateNumber = values["endDate"] as? NSNumber {
            
            let startDate = Date(timeIntervalSince1970: TimeInterval(startDateNumber.doubleValue / 1000))
            let endDate = Date(timeIntervalSince1970: TimeInterval(endDateNumber.doubleValue / 1000))
            
            for category in categories {
                if let biomarkerCategory = SahhaBiomarkerCategory(rawValue: category) {
                    biomarkerCategories.insert(biomarkerCategory)
                }
            }
            
            for type in types {
                if let biomarkerType = SahhaBiomarkerType(rawValue: type) {
                    biomarkerTypes.insert(biomarkerType)
                }
            }
            
            Sahha.getBiomarkers(categories: biomarkerCategories, types: biomarkerTypes, startDate: startDate, endDate: endDate) { error, value in
                if let error = error {
                    result(FlutterError(code: "Sahha Error", message: error, details: nil))
                } else if let value = value {
                    result(value)
                } else {
                    let message: String = "Requested Sahha Biomarkers not available"
                    Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getBiomarkers", body: params.debugDescription)
                    result(FlutterError(code: "Sahha Error", message: message, details: nil))
                }
            }
        } else {
            let message = "SahhaFlutter.getBiomarkers() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getBiomarkers", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func getStats(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let sensor = values["sensor"] as? String {
            if let startDateNumber = values["startDate"] as? NSNumber, let endDateNumber = values["endDate"] as? NSNumber {
                let startDate = Date(timeIntervalSince1970: TimeInterval(startDateNumber.doubleValue / 1000))
                let endDate = Date(timeIntervalSince1970: TimeInterval(endDateNumber.doubleValue / 1000))
                if let sahhaSensor = SahhaSensor(rawValue: sensor) {
                    Sahha.getStats(sensor: sahhaSensor, startDate: startDate, endDate: endDate) { error, value in
                        if let error = error {
                            result(FlutterError(code: "Sahha Error", message: error, details: nil))
                        } else {
                            var string: String?
                            do {
                                let jsonEncoder = JSONEncoder()
                                jsonEncoder.outputFormatting = .prettyPrinted
                                let jsonData = try jsonEncoder.encode(value)
                                string = String(data: jsonData, encoding: .utf8)
                            } catch let encodingError {
                                print(encodingError)
                                Sahha.postError(
                                    framework: .flutter,
                                    message: encodingError.localizedDescription,
                                    path: "SahhaFlutter", method: "getStats",
                                    body: "jsonEncoder")
                                result(FlutterError(code: "Sahha Error", message: encodingError.localizedDescription, details: nil))
                                return
                            }
                            result(string)
                        }
                    }
                }
            }
        } else {
            let message = "SahhaFlutter.getStats() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getStats", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
    private func getSamples(_ params: Any?, result: @escaping FlutterResult) {
        if let values = params as? [String: Any?], let sensor = values["sensor"] as? String {
            if let startDateNumber = values["startDate"] as? NSNumber, let endDateNumber = values["endDate"] as? NSNumber {
                let startDate = Date(timeIntervalSince1970: TimeInterval(startDateNumber.doubleValue / 1000))
                let endDate = Date(timeIntervalSince1970: TimeInterval(endDateNumber.doubleValue / 1000))
                if let sahhaSensor = SahhaSensor(rawValue: sensor) {
                    Sahha.getSamples(sensor: sahhaSensor, startDate: startDate, endDate: endDate) { error, value in
                        if let error = error {
                            result(FlutterError(code: "Sahha Error", message: error, details: nil))
                        } else {
                            var string: String?
                            do {
                                let jsonEncoder = JSONEncoder()
                                jsonEncoder.outputFormatting = .prettyPrinted
                                let jsonData = try jsonEncoder.encode(value)
                                string = String(data: jsonData, encoding: .utf8)
                            } catch let encodingError {
                                print(encodingError)
                                Sahha.postError(
                                    framework: .flutter,
                                    message: encodingError.localizedDescription,
                                    path: "SahhaFlutter", method: "getStats",
                                    body: "jsonEncoder")
                                result(FlutterError(code: "Sahha Error", message: encodingError.localizedDescription, details: nil))
                                return
                            }
                            result(string)
                        }
                    }
                }
            }
        } else {
            let message = "SahhaFlutter.getSamples() parameters are invalid"
            Sahha.postError(framework: .flutter, message: message, path: "SwiftSahhaFlutterPlugin", method: "getSamples", body: params.debugDescription)
            result(FlutterError(code: "Sahha Error", message: message, details: nil))
        }
    }
    
}
