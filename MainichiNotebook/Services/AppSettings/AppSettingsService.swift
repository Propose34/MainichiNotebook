import Foundation
import Combine

@MainActor
final class AppSettingsService: ObservableObject {
    @Published var settings: AppSettingsState
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("app-settings.json")
    }
    
    init() {
        let defaultSettings = AppSettingsState(
            themeMode: .system,
            notificationsEnabled: false,
            dailyReminderTime: DateComponents(hour: 9, minute: 0), // 09:00 AM default
            soundEffectsEnabled: true,
            hapticsEnabled: true,
            showDeveloperDiagnostics: false,
            updatedAt: Date()
        )
        
        self.settings = defaultSettings
        loadSettings()
    }
    
    func loadSettings() {
        let path = fileURL
        guard FileManager.default.fileExists(atPath: path.path) else {
            saveSettings()
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            let decoded = try JSONDecoder().decode(AppSettingsState.self, from: data)
            self.settings = decoded
            print("[AppSettingsService] Loaded app settings.")
        } catch {
            print("[AppSettingsService] Failed to load app settings, using defaults: \(error.localizedDescription)")
        }
    }
    
    func saveSettings() {
        let path = fileURL
        do {
            settings.updatedAt = Date()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            try data.write(to: path, options: .atomic)
            print("[AppSettingsService] Saved app settings successfully.")
        } catch {
            print("[AppSettingsService] Failed to save app settings: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Updaters
    
    func updateThemeMode(_ mode: AppThemeMode) {
        settings.themeMode = mode
        saveSettings()
    }
    
    func updateNotificationsEnabled(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        saveSettings()
    }
    
    func updateDailyReminderTime(_ components: DateComponents) {
        settings.dailyReminderTime = components
        saveSettings()
    }
    
    func updateSoundEffectsEnabled(_ enabled: Bool) {
        settings.soundEffectsEnabled = enabled
        saveSettings()
    }
    
    func updateHapticsEnabled(_ enabled: Bool) {
        settings.hapticsEnabled = enabled
        saveSettings()
    }
    
    func updateShowDeveloperDiagnostics(_ enabled: Bool) {
        settings.showDeveloperDiagnostics = enabled
        saveSettings()
    }
}
