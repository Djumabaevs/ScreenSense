import Foundation

final class AppGroupManager {
    static let shared = AppGroupManager()
    
    private let suiteName = AppConstants.appGroupID
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    func save<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)
    }
    
    func load<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    func remove(forKey key: String) {
        defaults?.removeObject(forKey: key)
    }
}
