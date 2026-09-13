import SwiftUI

struct AppSettingsScreen: View {
    @EnvironmentObject private var settingsService: AppSettingsService
    @EnvironmentObject private var userProfileService: UserProfileService
    @EnvironmentObject private var notificationService: LocalNotificationService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var reminderTime = Date()
    @State private var showProfileEditor = false
    @State private var showPermissionDeniedAlert = false
    
    private var activeColorScheme: ColorScheme? {
        switch settingsService.settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    let presets = [
        ("preset_cherry", "🌸"),
        ("preset_kitsune", "🦊"),
        ("preset_castle", "🏯"),
        ("preset_onigiri", "🍙"),
        ("preset_daruma", "🏮"),
        ("preset_sushi", "🍣"),
        ("preset_cat", "🐱")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Profile Summary
                Section(header: customSectionHeader("UserProfile / โปรไฟล์")) {
                    profileSummaryRow
                }
                .listRowBackground(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
                
                // Section 2: Appearance
                Section(header: customSectionHeader("Appearance / ธีม")) {
                    Picker("Theme Mode", selection: Binding(
                        get: { settingsService.settings.themeMode },
                        set: { settingsService.updateThemeMode($0) }
                    )) {
                        ForEach(AppThemeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                .listRowBackground(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
                
                // Section 3: Study Reminders
                Section(header: customSectionHeader("Study Reminders / การเตือนเรียนหนังสือ")) {
                    Toggle("Enable Daily Reminders", isOn: Binding(
                        get: { settingsService.settings.notificationsEnabled },
                        set: { settingsService.updateNotificationsEnabled($0) }
                    ))
                    
                    if settingsService.settings.notificationsEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { newTime in
                                saveTime(newTime)
                            }
                        
                        Text("Reminders will send a local notification to help you stay consistent.")
                            .font(AppTheme.fontRounded(size: 11))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                            .listRowBackground(Color.clear)
                    }
                }
                .listRowBackground(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
                
                // Section 4: Study Preferences
                Section(header: customSectionHeader("Preferences / เสียงและการสั่น")) {
                    Toggle("Sound Effects", isOn: Binding(
                        get: { settingsService.settings.soundEffectsEnabled },
                        set: { settingsService.updateSoundEffectsEnabled($0) }
                    ))
                    
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settingsService.settings.hapticsEnabled },
                        set: { settingsService.updateHapticsEnabled($0) }
                    ))
                }
                .listRowBackground(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
                
                // Section 5: Developer Diagnostics
                Section(header: customSectionHeader("Developer / สำหรับนักพัฒนา")) {
                    Toggle("Show Diagnostics Info", isOn: Binding(
                        get: { settingsService.settings.showDeveloperDiagnostics },
                        set: { settingsService.updateShowDeveloperDiagnostics($0) }
                    ))
                    
                    if settingsService.settings.showDeveloperDiagnostics {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Documents Storage Info:")
                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                            Text("Profile: Documents/MainichiUserData/user-profile.json")
                            Text("Settings: Documents/MainichiUserData/app-settings.json")
                            Text("Avatar: Documents/MainichiUserData/Profile/avatar.jpg")
                        }
                        .font(AppTheme.fontRounded(size: 11))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
            }
            .background(colorScheme == .dark ? AppTheme.darkNavy : AppTheme.paperBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                    .font(AppTheme.fontRounded(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $showProfileEditor) {
                ProfileSettingsScreen()
            }
            .alert("Notifications Permission Denied", isPresented: $showPermissionDeniedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enable notifications for Mainichi Notebook in System Settings to receive daily study reminders.")
            }
            .onAppear {
                loadTime()
            }
            .onChange(of: settingsService.settings.notificationsEnabled) { enabled in
                if enabled {
                    notificationService.requestPermission { granted in
                        if granted {
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                            notificationService.scheduleDailyReminder(
                                hour: comps.hour ?? 9,
                                minute: comps.minute ?? 0
                            )
                        } else {
                            settingsService.updateNotificationsEnabled(false)
                            showPermissionDeniedAlert = true
                        }
                    }
                } else {
                    notificationService.cancelAllReminders()
                }
            }
            .preferredColorScheme(activeColorScheme)
        }
    }
    
    // MARK: - Subviews
    
    private var profileSummaryRow: some View {
        Button(action: {
            showProfileEditor = true
        }) {
            HStack(spacing: 16) {
                // Profile Avatar View
                ZStack {
                    Circle()
                        .stroke(AppTheme.sakuraPink.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 54, height: 54)
                    
                    if let avatar = userProfileService.profile.avatarImageFileName {
                        if avatar == "avatar.jpg",
                           let uiImage = UIImage(contentsOfFile: userProfileService.customAvatarURL.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } else if let preset = presets.first(where: { $0.0 == avatar }) {
                            Text(preset.1)
                                .font(.system(size: 26))
                                .frame(width: 48, height: 48)
                                .background(AppTheme.sakuraPinkLight)
                                .clipShape(Circle())
                        } else {
                            defaultAvatarPlaceholder
                        }
                    } else {
                        defaultAvatarPlaceholder
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfileService.profile.displayName)
                        .font(AppTheme.fontSerif(size: 18, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                    
                    if let nickname = userProfileService.profile.nickname {
                        Text("@\(nickname)")
                            .font(AppTheme.fontRounded(size: 12))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                    } else {
                        Text("Tap to edit profile")
                            .font(AppTheme.fontRounded(size: 12))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : AppTheme.textMuted.opacity(0.5))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var defaultAvatarPlaceholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 22))
            .foregroundColor(AppTheme.textMuted)
            .frame(width: 48, height: 48)
            .background(AppTheme.paperBeige)
            .clipShape(Circle())
    }
    
    // MARK: - Custom Helpers
    
    private func customSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.fontRounded(size: 11, weight: .bold))
            .foregroundColor(colorScheme == .dark ? Color(hex: "EAA09B") : Color(hex: "131B26"))
            .textCase(.none)
            .padding(.vertical, 2)
    }
    
    // MARK: - Time Helpers
    
    private func loadTime() {
        if let comps = settingsService.settings.dailyReminderTime,
           let hour = comps.hour,
           let minute = comps.minute {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            var newComps = DateComponents()
            newComps.hour = hour
            newComps.minute = minute
            if let date = calendar.date(from: newComps) {
                reminderTime = date
                return
            }
        }
        
        let calendar = Calendar.current
        var fallbackComps = DateComponents()
        fallbackComps.hour = 9
        fallbackComps.minute = 0
        if let date = calendar.date(from: fallbackComps) {
            reminderTime = date
        }
    }
    
    private func saveTime(_ date: Date) {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        settingsService.updateDailyReminderTime(comps)
        
        if settingsService.settings.notificationsEnabled {
            notificationService.scheduleDailyReminder(
                hour: comps.hour ?? 9,
                minute: comps.minute ?? 0
            )
        }
    }
}
