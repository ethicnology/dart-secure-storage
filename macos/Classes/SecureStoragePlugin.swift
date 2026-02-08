import FlutterMacOS
import Security

public class SecureStoragePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "secure_storage", binaryMessenger: registrar.messenger)
    let instance = SecureStoragePlugin()
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
          let alias = args["alias"] as? String,
          let data = args["data"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "bad_args", message: "Missing alias or data.", details: nil))
      return
    }
    let accessibility = SecAccessibility.fromDart(args["accessibility"] as? String)
    let status = SecItemAdd(alias: alias, data: data.data, accessibility: accessibility)
    guard status == errSecSuccess else {
      result(FlutterError(code: "sec_item_add_failed", message: String(status), details: nil))
      return
    }
    result(nil)
  }

  private func handleKeychainContains(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let alias = args["alias"] as? String else {
      result(FlutterError(code: "bad_args", message: "Missing alias.", details: nil))
      return
    }
    result(SecItemExists(alias: alias))
  }

  private func handleSecItemCopyMatching(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let alias = args["alias"] as? String else {
      result(FlutterError(code: "bad_args", message: "Missing alias.", details: nil))
      return
    }
    if let keyData = SecItemCopyMatching(alias: alias) {
      result(FlutterStandardTypedData(bytes: keyData))
    } else {
      result(nil)
    }
  }

  private func handleSecItemDelete(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let alias = args["alias"] as? String else {
      result(FlutterError(code: "bad_args", message: "Missing alias.", details: nil))
      return
    }
    let status = SecItemDelete(alias: alias)
    if status == errSecSuccess || status == errSecItemNotFound {
      result(nil)
    } else {
      result(FlutterError(code: "sec_item_delete_failed", message: String(status), details: nil))
    }
  }
}

private func keychainQuery(alias: String, returnData: Bool) -> [String: Any] {
  var query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: alias,
    kSecMatchLimit as String: kSecMatchLimitOne,
  ]
  query[kSecReturnData as String] = returnData
  return query
}

private func SecItemCopyMatching(alias: String) -> Data? {
  let query = keychainQuery(alias: alias, returnData: true)
  var item: CFTypeRef?
  let status = Security.SecItemCopyMatching(query as CFDictionary, &item)
  guard status == errSecSuccess else { return nil }
  return item as? Data
}

private func SecItemExists(alias: String) -> Bool {
  let query = keychainQuery(alias: alias, returnData: false)
  let status = Security.SecItemCopyMatching(query as CFDictionary, nil)
  return status == errSecSuccess
}

private enum SecAccessibility {
  case whenUnlocked
  case whenUnlockedThisDeviceOnly
  case afterFirstUnlock
  case afterFirstUnlockThisDeviceOnly

  static func fromDart(_ value: String?) -> CFString {
    switch value {
    case "whenUnlocked": return kSecAttrAccessibleWhenUnlocked
    case "afterFirstUnlock": return kSecAttrAccessibleAfterFirstUnlock
    case "afterFirstUnlockThisDeviceOnly": return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    case "whenPasscodeSetThisDeviceOnly", "whenUnlockedThisDeviceOnly", nil: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    default: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }
  }
}

private func SecItemAdd(alias: String, data: Data, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) -> OSStatus {
  var matchQuery = keychainQuery(alias: alias, returnData: false)
  let attributes: [String: Any] = [kSecValueData as String: data]
  if SecItemExists(alias: alias) {
    return Security.SecItemUpdate(matchQuery as CFDictionary, attributes as CFDictionary)
  }
  matchQuery[kSecAttrAccessible as String] = accessibility
  matchQuery[kSecValueData as String] = data
  return Security.SecItemAdd(matchQuery as CFDictionary, nil)
}

private func SecItemDelete(alias: String) -> OSStatus {
  let query = keychainQuery(alias: alias, returnData: false)
  return Security.SecItemDelete(query as CFDictionary)
}
