import Foundation
import Security

final class AppGroupManager {
    static let shared = AppGroupManager()

    private let appGroupID = AppConstants.appGroupID
    private let fileManager = FileManager.default

    private lazy var sharedDefaults: UserDefaults? = {
        UserDefaults(suiteName: appGroupID)
    }()

    var isSharedContainerAvailable: Bool {
        sharedDefaults != nil
    }

    var sharedContainerPath: String? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?.path
    }

    @discardableResult
    func save<T: Codable>(_ value: T, forKey key: String) -> Bool {
        guard let defaults = sharedDefaults else {
            print("[AppGroupManager] UserDefaults suite unavailable for key '\(key)'")
            return false
        }

        guard let data = try? JSONEncoder().encode(value) else {
            print("[AppGroupManager] Failed to encode value for key '\(key)'")
            return false
        }

        defaults.set(data, forKey: key)
        defaults.synchronize()
        return true
    }

    func load<T: Codable>(forKey key: String) -> T? {
        guard let defaults = sharedDefaults else {
            return nil
        }

        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("[AppGroupManager] Failed to decode key '\(key)': \(error)")
            return nil
        }
    }

    func remove(forKey key: String) {
        sharedDefaults?.removeObject(forKey: key)
        sharedDefaults?.synchronize()
    }
}

// MARK: - Keychain-based transport (no App Groups required)

enum KeychainTransport {
    private static let service = "com.screensense.shared-data"
    private static let account = "latestDailyData"

    static func save(_ data: SharedDailyData) -> Bool {
        guard let encoded = try? JSONEncoder().encode(data) else {
            return false
        }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: encoded,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        var status = SecItemAdd(addQuery as CFDictionary, nil)

        // If default access group fails, try with explicit team group
        if status != errSecSuccess {
            addQuery[kSecAttrAccessGroup as String] = "R56999TGTG.*"
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        return status == errSecSuccess
    }

    static func load() -> SharedDailyData? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(SharedDailyData.self, from: data)
    }
}
