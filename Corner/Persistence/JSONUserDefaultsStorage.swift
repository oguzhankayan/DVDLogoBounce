import Foundation

/// A tiny helper that reads/writes a `Codable` value as JSON in `UserDefaults`.
/// Keeps the two stores below trivial and identical in behaviour.
struct JSONUserDefaultsStorage<Value: Codable> {
    let key: String
    let defaults: UserDefaults

    init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            // Corrupt / incompatible payload — drop it so we fall back to defaults
            // instead of getting stuck.
            #if DEBUG
            print("[Corner] Failed to decode \(Value.self) for key \"\(key)\": \(error)")
            #endif
            defaults.removeObject(forKey: key)
            return nil
        }
    }

    func save(_ value: Value) {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } catch {
            #if DEBUG
            print("[Corner] Failed to encode \(Value.self) for key \"\(key)\": \(error)")
            #endif
        }
    }

    func clear() { defaults.removeObject(forKey: key) }
}

enum DefaultsKey {
    static let settings = "corner.settings.v1"
    static let statistics = "corner.statistics.v1"
}
