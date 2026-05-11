import Foundation

/// `SettingsPersisting` backed by `UserDefaults` (JSON‑encoded snapshot).
public final class UserDefaultsSettingsStore: SettingsPersisting, @unchecked Sendable {
    private let storage: JSONUserDefaultsStorage<AppSettings.Snapshot>

    public init(defaults: UserDefaults = .standard) {
        storage = JSONUserDefaultsStorage(key: DefaultsKey.settings, defaults: defaults)
    }

    public func load() -> AppSettings.Snapshot? { storage.load() }
    public func save(_ snapshot: AppSettings.Snapshot) { storage.save(snapshot) }
    public func clear() { storage.clear() }
}
