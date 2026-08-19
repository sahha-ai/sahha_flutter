#if DEBUG

import Flutter
import Foundation
import HealthKit

/// Debug-only sabotage channel behind the example app's Stress Lab screen.
///
/// This lives in the Runner, never in the plugin. It writes only surfaces the
/// SDK genuinely reads — `UserDefaults` keys, keychain items under the SDK's
/// own service, and app-wide HealthKit APIs — so every state it produces is one
/// a real device can reach on its own, through a bad upgrade, an OS restore or
/// a server-side token rotation.
///
/// The key names and value encodings below mirror the SDK's storage contract.
/// They are duplicated rather than imported because `StorageKeys` is internal,
/// and because the Runner must keep compiling when the local-SDK pod override
/// in `Podfile` is commented out.
enum ChaosChannel {
    static let channelName = "sahha_flutter_example/chaos"

    private enum Key {
        static let sensors = "sensors"
        static let deviceId = "deviceId"
        static let anchor = "hkAnchor."
        static let anchorDate = "hkAnchorDate."
        static let legacyAnchor = "sahha_hkAnchor."
        static let legacyAnchorDate = "date_hkAnchorDate."
        static let keychainService = "ai.sahha.ios"
        static let tokenAccount = "token"
        static let demographicAccount = "demographic"
    }

    /// The claim the SDK reads to populate `authSnapshot.profileId`. Carried
    /// across every forged token so data-log IDs keep a stable identity.
    private static let profileIdClaim = "https://api.sahha.ai/claims/profileId"

    /// How a forged token's `exp` is placed relative to now, and whether its
    /// signature is left deliberately unusable.
    private struct Forge {
        /// Seconds from now. Negative is already expired.
        let expiresIn: TimeInterval
        let bogusSignature: Bool
    }

    /// `AuthManager` refreshes proactively when a profile token expires within
    /// its 30-minute offset, so a token five minutes from expiry is already
    /// "expired" to `getValidProfileToken()` without being expired in absolute
    /// terms. That window is what `expireProfileTokenSoon` exercises.
    private static let proactiveRefreshOffset: TimeInterval = 30 * 60

    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            handle(call, result)
        }
    }

    // MARK: - Dispatch

    private static func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "poisonStoreLegacy":
                // 1.3.7-era raw values, from SahhaSensor.legacyRenames.
                result(try writeSensorRawValues([
                    "dietary_biotin", "dietary_caffeine", "dietary_fat_total", "sleep", "steps",
                ]))

            case "poisonStoreMixed":
                result(try writeSensorRawValues(["steps", "sleep", "not_a_sensor"]))

            case "poisonStoreAllUnknown":
                // Downgrade simulation: values only a newer SDK would know.
                result(try writeSensorRawValues(["from_the_future_a", "from_the_future_b"]))

            case "poisonStoreForeign":
                // A plain String, not Data — someone else's value under our key.
                UserDefaults.standard.set("not-sdk-shaped", forKey: Key.sensors)
                result(["wrote": "String", "key": Key.sensors])

            case "poisonStoreGarbage":
                var bytes = Data(count: 32)
                for index in bytes.indices { bytes[index] = UInt8.random(in: 0...255) }
                UserDefaults.standard.set(bytes, forKey: Key.sensors)
                result(["wrote": "Data", "byteCount": bytes.count, "key": Key.sensors])

            case "relocateAnchorsToLegacyKeys":
                result(relocateAnchorsToLegacyKeys())

            case "disableAllHKBackgroundDelivery":
                disableAllHKBackgroundDelivery(result)

            case "expireProfileToken":
                result(try rewriteTokens(profile: Forge(expiresIn: -3600, bogusSignature: false)))

            case "expireProfileTokenSoon":
                result(try rewriteTokens(profile: Forge(expiresIn: 300, bogusSignature: false)))

            case "invalidateProfileToken":
                result(try rewriteTokens(profile: Forge(expiresIn: 86400, bogusSignature: true)))

            case "expireRefreshToken":
                result(try rewriteTokens(refresh: Forge(expiresIn: -3600, bogusSignature: false)))

            case "invalidateBothTokens":
                result(try rewriteTokens(
                    profile: Forge(expiresIn: 86400, bogusSignature: true),
                    refresh: Forge(expiresIn: 86400, bogusSignature: true)
                ))

            case "inspectStorage":
                result(inspectStorage())

            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(
                code: "chaos_failed",
                message: (error as? ChaosError)?.message ?? error.localizedDescription,
                details: call.method
            ))
        }
    }

    private struct ChaosError: Error {
        let message: String
    }

    // MARK: - Sensor store

    /// The SDK stores the sensor set as `JSONEncoder` output for
    /// `Set<SahhaSensor>` — a JSON array of raw-value strings, held as `Data`.
    private static func writeSensorRawValues(_ rawValues: [String]) throws -> [String: Any] {
        let data = try JSONSerialization.data(withJSONObject: rawValues)
        UserDefaults.standard.set(data, forKey: Key.sensors)
        return ["wrote": "Data", "byteCount": data.count, "values": rawValues, "key": Key.sensors]
    }

    // MARK: - Anchors

    /// Moves every modern anchor default to the pre-rename key an upgrading
    /// install would have left behind, so the next read has to find them
    /// through the store's legacy alias or restart collection from scratch.
    private static func relocateAnchorsToLegacyKeys() -> [String: Any] {
        let defaults = UserDefaults.standard
        let keys = Array(defaults.dictionaryRepresentation().keys)
        var moved = 0

        for (modernPrefix, legacyPrefix) in [
            (Key.anchor, Key.legacyAnchor),
            (Key.anchorDate, Key.legacyAnchorDate),
        ] {
            for key in keys where key.hasPrefix(modernPrefix) {
                guard let value = defaults.object(forKey: key) else { continue }
                let suffix = String(key.dropFirst(modernPrefix.count))
                defaults.set(value, forKey: legacyPrefix + suffix)
                defaults.removeObject(forKey: key)
                moved += 1
            }
        }

        return ["moved": moved, "remaining": anchorCounts()]
    }

    private static func anchorCounts() -> [String: Int] {
        let keys = Array(UserDefaults.standard.dictionaryRepresentation().keys)
        func count(_ prefix: String) -> Int { keys.filter { $0.hasPrefix(prefix) }.count }
        return [
            Key.anchor: count(Key.anchor),
            Key.anchorDate: count(Key.anchorDate),
            Key.legacyAnchor: count(Key.legacyAnchor),
            Key.legacyAnchorDate: count(Key.legacyAnchorDate),
        ]
    }

    // MARK: - HealthKit

    /// The app-wide teardown an iOS update or a device restore performs on its
    /// own, diverging real HealthKit state from the SDK's bookkeeping.
    private static func disableAllHKBackgroundDelivery(_ result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(FlutterError(
                code: "chaos_failed",
                message: "Health data is not available on this device.",
                details: "disableAllHKBackgroundDelivery"
            ))
            return
        }
        HKHealthStore().disableAllBackgroundDelivery { success, error in
            DispatchQueue.main.async {
                if let error {
                    result(FlutterError(
                        code: "chaos_failed",
                        message: error.localizedDescription,
                        details: "disableAllHKBackgroundDelivery"
                    ))
                } else {
                    result(["disabled": success])
                }
            }
        }
    }

    // MARK: - Token forging

    /// Rewrites the stored token pair in place.
    ///
    /// The keychain blob is mutated as JSON rather than through a mirrored
    /// `TokenResponse` struct, so every field the SDK wrote survives untouched
    /// and the result is guaranteed to still decode. A blob that will not
    /// decode exercises the unreadable-keychain path instead, which is a
    /// different test.
    private static func rewriteTokens(profile: Forge? = nil, refresh: Forge? = nil) throws -> [String: Any] {
        guard let data = try keychainRead(account: Key.tokenAccount) else {
            throw ChaosError(message: "No stored session in the keychain — authenticate first.")
        }
        guard var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ChaosError(message: "The stored session is not decodable JSON — nothing to forge from.")
        }
        guard let currentProfile = json["profileToken"] as? String,
              let currentRefresh = json["refreshToken"] as? String
        else {
            throw ChaosError(message: "The stored session is missing its token fields.")
        }

        // The profile id claim rides across from whichever token still carries
        // one, so authSnapshot.profileId stays populated after the rewrite.
        let profileId = claimedProfileId(currentProfile) ?? claimedProfileId(currentRefresh)
        var summary: [String: Any] = ["profileIdPreserved": profileId != nil]

        if let profile {
            let forged = forgeJWT(from: currentProfile, profileId: profileId, using: profile)
            json["profileToken"] = forged
            summary["profileToken"] = describe(profile)
        }
        if let refresh {
            let forged = forgeJWT(from: currentRefresh, profileId: profileId, using: refresh)
            json["refreshToken"] = forged
            summary["refreshToken"] = describe(refresh)
        }

        let rewritten = try JSONSerialization.data(withJSONObject: json)
        // Sanity gate: refuse to persist a blob the SDK could not read back.
        guard (try? JSONSerialization.jsonObject(with: rewritten)) != nil else {
            throw ChaosError(message: "Refusing to write a session blob that will not decode.")
        }
        try keychainWrite(rewritten, account: Key.tokenAccount)

        summary["note"] = "Force-quit and relaunch so the token store reloads from the keychain."
        return summary
    }

    private static func describe(_ forge: Forge) -> String {
        let minutes = Int(forge.expiresIn / 60)
        let clock: String
        if forge.expiresIn < 0 {
            clock = "expired \(-minutes)m ago"
        } else if forge.expiresIn < proactiveRefreshOffset {
            clock = "expires in \(minutes)m — inside the 30m proactive-refresh window"
        } else {
            clock = "expires in \(minutes)m — outside the 30m proactive-refresh window"
        }
        return forge.bogusSignature ? "\(clock), signature deliberately unusable" : clock
    }

    /// Rebuilds [original] as a still-decodable three-part JWT with a
    /// deliberate `exp`.
    ///
    /// Only the payload's `exp` moves; every other claim is carried across, so
    /// the local checks in `AuthManager` see a token they can decode and act
    /// on. Nothing on device verifies the signature — it decides only whether
    /// the *server* accepts the token, which is what separates a proactive
    /// refresh from a server-rejected one.
    private static func forgeJWT(from original: String, profileId: String?, using forge: Forge) -> String {
        let parts = original.split(separator: ".", omittingEmptySubsequences: false).map(String.init)

        let header = parts.count == 3 && !parts[0].isEmpty
            ? parts[0]
            : base64URLEncode(Data(#"{"alg":"HS256","typ":"JWT"}"#.utf8))

        var payload: [String: Any] = [:]
        if parts.count == 3,
           let decoded = base64URLDecode(parts[1]),
           let json = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any] {
            payload = json
        }
        if payload[profileIdClaim] == nil, let profileId {
            payload[profileIdClaim] = profileId
        }
        payload["exp"] = Date().addingTimeInterval(forge.expiresIn).timeIntervalSince1970

        let payloadData = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data("{}".utf8)
        let signature: String
        if forge.bogusSignature {
            signature = base64URLEncode(Data("stress-lab-not-a-valid-signature".utf8))
        } else {
            signature = parts.count == 3 && !parts[2].isEmpty ? parts[2] : base64URLEncode(Data("unsigned".utf8))
        }

        return "\(header).\(base64URLEncode(payloadData)).\(signature)"
    }

    private static func claimedProfileId(_ jwt: String) -> String? {
        let parts = jwt.split(separator: ".").map(String.init)
        guard parts.count == 3,
              let decoded = base64URLDecode(parts[1]),
              let json = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any]
        else { return nil }
        return json[profileIdClaim] as? String
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Mirrors the SDK's own base64url handling, so anything this encodes the
    /// SDK can decode.
    private static func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - base64.count % 4
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
        }
        return Data(base64Encoded: base64)
    }

    // MARK: - Keychain

    private static func keychainRead(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Key.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess: return item as? Data
        case errSecItemNotFound: return nil
        default: throw ChaosError(message: "Keychain read failed (OSStatus \(status)).")
        }
    }

    private static func keychainWrite(_ data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Key.keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        // Matches the SDK's own accessibility, so a background launch before
        // first unlock behaves the same either way.
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw ChaosError(message: "Keychain write failed (OSStatus \(status)).")
        }
    }

    /// Presence only. Token and demographic contents are never read back out
    /// of the keychain by this channel, and never leave the device.
    private static func keychainHasItem(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Key.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Inspector

    private static func inspectStorage() -> [String: Any] {
        [
            "sensors": inspectSensorStore(),
            "anchors": anchorCounts(),
            "keychain": [
                Key.tokenAccount: keychainHasItem(account: Key.tokenAccount),
                Key.demographicAccount: keychainHasItem(account: Key.demographicAccount),
            ],
            "deviceIdPresent": UserDefaults.standard.object(forKey: Key.deviceId) != nil,
            "sahhaFramework": sahhaFrameworkInfo(),
        ]
    }

    private static func inspectSensorStore() -> [String: Any] {
        guard let raw = UserDefaults.standard.object(forKey: Key.sensors) else {
            return ["present": false]
        }
        var report: [String: Any] = ["present": true, "type": String(describing: type(of: raw))]
        guard let data = raw as? Data else {
            // Foreign value: the type name is reported, never the value — the
            // same discipline the SDK's own anomaly report follows.
            return report
        }
        report["byteCount"] = data.count
        if let values = try? JSONSerialization.jsonObject(with: data) as? [String] {
            report["decoded"] = values
        } else {
            report["decoded"] = NSNull()
        }
        return report
    }

    /// Runtime proof of which Sahha build is actually loaded. The framework is
    /// found by bundle rather than by importing `Sahha`, so this file keeps
    /// compiling whether or not the local-SDK pod override is uncommented.
    private static func sahhaFrameworkInfo() -> [String: Any] {
        guard let bundle = Bundle.allFrameworks.first(where: {
            $0.bundleURL.lastPathComponent == "Sahha.framework"
        }) else {
            return ["loaded": false]
        }
        var info: [String: Any] = [
            "loaded": true,
            "version": bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build": bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
        ]
        // A locally rebuilt path pod carries a fresh binary timestamp; a pod
        // resolved from the CDN carries its download date.
        if let executable = bundle.executableURL,
           let modified = try? FileManager.default
               .attributesOfItem(atPath: executable.path)[.modificationDate] as? Date {
            info["binaryModified"] = ISO8601DateFormatter().string(from: modified)
        }
        return info
    }
}

#endif
