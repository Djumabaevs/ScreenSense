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

    /// Shared team keychain access group — works across app + extensions without App Group
    private static let teamAccessGroup = "R56999TGTG.com.screensense.shared-data"

    @discardableResult
    static func save(_ data: SharedDailyData) -> Bool {
        guard let encoded = try? JSONEncoder().encode(data) else {
            return false
        }

        // Delete any existing items (both with and without access group)
        for accessGroup in [teamAccessGroup, AppConstants.appGroupID, nil] as [String?] {
            var deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
            ]
            if let group = accessGroup {
                deleteQuery[kSecAttrAccessGroup as String] = group
            }
            SecItemDelete(deleteQuery as CFDictionary)
        }

        // Save with team-prefixed access group (works across app + extension)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: encoded,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: teamAccessGroup,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        print("[KeychainTransport] Save status: \(status) (0=success)")
        return status == errSecSuccess
    }

    static func load() -> SharedDailyData? {
        // Try team access group first (shared between app + extension)
        for accessGroup in [teamAccessGroup, AppConstants.appGroupID, nil] as [String?] {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            if let group = accessGroup {
                query[kSecAttrAccessGroup as String] = group
            }

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess, let data = result as? Data,
               let decoded = try? JSONDecoder().decode(SharedDailyData.self, from: data) {
                print("[KeychainTransport] Loaded from group: \(accessGroup ?? "default")")
                return decoded
            }
        }

        print("[KeychainTransport] No data found in any access group")
        return nil
    }
}
