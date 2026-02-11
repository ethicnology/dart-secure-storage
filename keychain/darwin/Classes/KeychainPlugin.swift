#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif
import Security

private struct KeychainParams {
  let alias: String
  let service: String?
  let accessibility: CFString
  let useDataProtection: Bool
  let authenticationRequired: Bool
  let biometryCurrentSetOnly: Bool
  let authenticationPrompt: String?

  static func from(_ args: [String: Any]) -> KeychainParams? {
    guard let alias = args["alias"] as? String else { return nil }
    return KeychainParams(
      alias: alias,
      service: args["service"] as? String,
      accessibility: SecAccessibility.fromDart(args["accessibility"] as? String),
      useDataProtection: args["useDataProtection"] as? Bool ?? false,
      authenticationRequired: args["authenticationRequired"] as? Bool ?? false,
      biometryCurrentSetOnly: args["biometryCurrentSetOnly"] as? Bool ?? false,
      authenticationPrompt: args["authenticationPrompt"] as? String
    )
  }
}

private let serialQueue = DispatchQueue(label: "com.oubliette.keychain", qos: .userInitiated)

public class KeychainPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let channel = FlutterMethodChannel(name: "keychain", binaryMessenger: registrar.messenger())
    #else
    let channel = FlutterMethodChannel(name: "keychain", binaryMessenger: registrar.messenger)
    #endif
    let instance = KeychainPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "secItemAdd":
      handleSecItemAdd(call, result: result)
    case "secItemCopyMatching":
      handleSecItemCopyMatching(call, result: result)
    case "secItemDelete":
      handleSecItemDelete(call, result: result)
    case "keychainContains":
      handleKeychainContains(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleSecItemAdd(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let params = KeychainParams.from(args),
          let data = args["data"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "bad_args", message: "Missing alias or data.", details: nil))
      return
    }
    serialQueue.async {
      let status = secItemAdd(params: params, data: data.data)
      DispatchQueue.main.async {
        guard status == errSecSuccess else {
          result(FlutterError(code: "sec_item_add_failed", message: String(status), details: nil))
          return
        }
        result(nil)
      }
    }
  }

  private func handleKeychainContains(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let params = KeychainParams.from(args) else {
      result(FlutterError(code: "bad_args", message: "Missing alias.", details: nil))
      return
    }
    result(secItemExists(params: params))
  }

  private func handleSecItemCopyMatching(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let params = KeychainParams.from(args) else {
      result(FlutterError(code: "bad_args", message: "Missing alias.", details: nil))
      return
    }
    serialQueue.async {
      var query = keychainReadQuery(params: params, returnData: true)
      if let prompt = params.authenticationPrompt {
        query[kSecUseOperationPrompt as String] = prompt
      }
      var item: CFTypeRef?
      let status = Security.SecItemCopyMatching(query as CFDictionary, &item)
      DispatchQueue.main.async {
        switch status {
        case errSecSuccess:
          if let data = item as? Data {
            result(FlutterStandardTypedData(bytes: data))
          } else {
            result(nil)
          }
        case errSecItemNotFound:
          result(nil)
        case errSecUserCanceled:
          result(FlutterError(code: "auth_cancelled", message: "User cancelled authentication.", details: nil))
        case errSecAuthFailed:
          result(FlutterError(code: "auth_failed", message: "Authentication failed.", details: nil))
        case errSecInteractionNotAllowed:
          result(FlutterError(code: "interaction_not_allowed", message: "Keychain interaction not allowed (device locked?).", details: nil))
        default:
          result(FlutterError(code: "sec_item_copy_failed", message: String(status), details: nil))
        }
      }
    }
  }

  private func handleSecItemDelete(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let params = KeychainParams.from(args) else {
      result(FlutterError(code: "bad_args", message: "Missing alias.", details: nil))
      return
    }
    let status = secItemDelete(params: params)
    if status == errSecSuccess || status == errSecItemNotFound {
      result(nil)
    } else {
      result(FlutterError(code: "sec_item_delete_failed", message: String(status), details: nil))
    }
  }
}

private enum SecAccessibility {
  static func fromDart(_ value: String?) -> CFString {
    switch value {
    case "whenUnlocked": return kSecAttrAccessibleWhenUnlocked
    case "afterFirstUnlock": return kSecAttrAccessibleAfterFirstUnlock
    case "afterFirstUnlockThisDeviceOnly": return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    case "whenPasscodeSetThisDeviceOnly": return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    case "whenUnlockedThisDeviceOnly", nil: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    default: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }
  }
}

private func keychainQuery(params: KeychainParams) -> [String: Any] {
  var query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: params.alias,
    kSecAttrSynchronizable as String: kCFBooleanFalse as Any
  ]
  if let service = params.service {
    query[kSecAttrService as String] = service
  }
  #if os(macOS)
  if (params.useDataProtection || params.authenticationRequired), #available(macOS 10.15, *) {
    query[kSecUseDataProtectionKeychain as String] = true
  }
  #endif
  return query
}

private func keychainReadQuery(params: KeychainParams, returnData: Bool) -> [String: Any] {
  var query = keychainQuery(params: params)
  query[kSecMatchLimit as String] = kSecMatchLimitOne
  query[kSecReturnData as String] = returnData
  return query
}

private func secItemExists(params: KeychainParams) -> Bool {
  let query = keychainReadQuery(params: params, returnData: false)
  let status = Security.SecItemCopyMatching(query as CFDictionary, nil)
  return status == errSecSuccess
}

private func createAccessControl(params: KeychainParams) -> SecAccessControl? {
  let flags: SecAccessControlCreateFlags = params.biometryCurrentSetOnly
    ? .biometryCurrentSet
    : .userPresence
  var error: Unmanaged<CFError>?
  let accessControl = SecAccessControlCreateWithFlags(
    nil,
    params.accessibility,
    flags,
    &error
  )
  if let error = error?.takeRetainedValue() {
    NSLog("KeychainPlugin: Error creating access control: \(error.localizedDescription)")
    return nil
  }
  return accessControl
}

private func secItemAdd(params: KeychainParams, data: Data) -> OSStatus {
  var matchQuery = keychainQuery(params: params)
  let attributes: [String: Any] = [kSecValueData as String: data]
  if secItemExists(params: params) {
    return Security.SecItemUpdate(matchQuery as CFDictionary, attributes as CFDictionary)
  }
  if params.authenticationRequired, let accessControl = createAccessControl(params: params) {
    matchQuery[kSecAttrAccessControl as String] = accessControl
  } else {
    matchQuery[kSecAttrAccessible as String] = params.accessibility
  }
  matchQuery[kSecValueData as String] = data
  return Security.SecItemAdd(matchQuery as CFDictionary, nil)
}

private func secItemDelete(params: KeychainParams) -> OSStatus {
  let query = keychainQuery(params: params)
  return Security.SecItemDelete(query as CFDictionary)
}
