import Foundation

struct AppSettingsState: Codable, Hashable {
    var themeMode: AppThemeMode
    var notificationsEnabled: Bool
    var dailyReminderTime: DateComponents?
    var soundEffectsEnabled: Bool
    var hapticsEnabled: Bool
    var showDeveloperDiagnostics: Bool
    var updatedAt: Date
}
