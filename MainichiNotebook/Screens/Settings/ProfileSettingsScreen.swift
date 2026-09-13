import SwiftUI
import PhotosUI

struct ProfileSettingsScreen: View {
    @EnvironmentObject private var userProfileService: UserProfileService
    @EnvironmentObject private var settingsService: AppSettingsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var displayName = ""
    @State private var nickname = ""
    @State private var selectedLevel = "Beginner"
    @State private var studyGoal = "Prepare for JLPT N5"
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    private var activeColorScheme: ColorScheme? {
        switch settingsService.settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    let levels = ["Beginner", "N5", "N4", "N3", "N2", "N1", "Custom / Not sure"]
    let goals = [
        "Learn classroom Japanese",
        "Practice vocabulary daily",
        "Prepare for JLPT N5",
        "Personal study"
    ]
    
    let presets = [
        ("preset_cherry", "🌸", "Cherry"),
        ("preset_kitsune", "🦊", "Kitsune"),
        ("preset_castle", "🏯", "Castle"),
        ("preset_onigiri", "🍙", "Onigiri"),
        ("preset_daruma", "🏮", "Daruma"),
        ("preset_sushi", "🍣", "Sushi"),
        ("preset_cat", "🐱", "Neko")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Header Section
                    avatarHeaderSection
                    
                    // Personal Information Card
                    personalInfoCard
                    
                    // Study Preferences Card
                    studyPrefsCard
                }
                .padding(.vertical, 20)
            }
            .background(colorScheme == .dark ? AppTheme.darkNavy : AppTheme.paperBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userProfileService.updateProfile(
                            displayName: displayName,
                            nickname: nickname.isEmpty ? nil : nickname,
                            studyGoal: studyGoal,
                            japaneseLevel: selectedLevel
                        )
                        dismiss()
                    }
                    .font(AppTheme.fontRounded(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                }
            }
            .onAppear {
                displayName = userProfileService.profile.displayName
                nickname = userProfileService.profile.nickname ?? ""
                selectedLevel = userProfileService.profile.japaneseLevel ?? "Beginner"
                studyGoal = userProfileService.profile.studyGoal ?? "Prepare for JLPT N5"
            }
            .onChange(of: selectedPhotoItem) { newItem in
                if let item = newItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            userProfileService.saveCustomAvatar(imageData: data)
                        }
                    }
                }
            }
            .preferredColorScheme(activeColorScheme)
        }
    }
    
    // MARK: - Subviews
    
    private var avatarHeaderSection: some View {
        VStack(spacing: 16) {
            // Render Profile Image
            ZStack {
                Circle()
                    .stroke(AppTheme.sakuraPink.opacity(0.4), lineWidth: 2)
                    .frame(width: 100, height: 100)
                
                if let avatar = userProfileService.profile.avatarImageFileName {
                    if avatar == "avatar.jpg",
                       let uiImage = UIImage(contentsOfFile: userProfileService.customAvatarURL.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 92)
                            .clipShape(Circle())
                    } else if let preset = presets.first(where: { $0.0 == avatar }) {
                        Text(preset.1)
                            .font(.system(size: 54))
                            .frame(width: 92, height: 92)
                            .background(AppTheme.sakuraPinkLight)
                            .clipShape(Circle())
                    } else {
                        // Fallback default
                        defaultAvatarPlaceholder
                    }
                } else {
                    defaultAvatarPlaceholder
                }
            }
            
            // Picker buttons
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose Photo")
                    }
                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.sakuraPink)
                    .cornerRadius(8)
                }
                
                if userProfileService.profile.avatarImageFileName != nil {
                    Button(action: {
                        userProfileService.removeAvatar()
                    }) {
                        Text("Reset")
                            .font(AppTheme.fontRounded(size: 13, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperBeige)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1)
                            )
                    }
                }
            }
            
            // Built-in presets shelf
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Built-in Mascot / เลือกรูปมาสคอต")
                    .font(AppTheme.fontRounded(size: 12, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presets, id: \.0) { preset in
                            let isSelected = userProfileService.profile.avatarImageFileName == preset.0
                            Button(action: {
                                withAnimation {
                                    userProfileService.updatePresetAvatar(name: preset.0)
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text(preset.1)
                                        .font(.system(size: 32))
                                        .frame(width: 54, height: 54)
                                        .background(isSelected ? AppTheme.sakuraPinkLight : (colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperBeige.opacity(0.4)))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? AppTheme.sakuraPink : (colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight), lineWidth: isSelected ? 2 : 1)
                                        )
                                    Text(preset.2)
                                        .font(AppTheme.fontRounded(size: 10, weight: .medium))
                                        .foregroundColor(isSelected ? AppTheme.sakuraPink : (colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var defaultAvatarPlaceholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 40))
            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
            .frame(width: 92, height: 92)
            .background(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperBeige)
            .clipShape(Circle())
    }
    
    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information / ข้อมูลส่วนตัว")
                .font(AppTheme.fontSerif(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
            
            VStack(spacing: 12) {
                // Display Name Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Display Name")
                        .font(AppTheme.fontRounded(size: 11, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                    
                    TextField("Enter name", text: $displayName)
                        .font(AppTheme.fontRounded(size: 14))
                        .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(colorScheme == .dark ? AppTheme.darkNavy.opacity(0.6) : AppTheme.paperBeige.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1)
                        )
                }
                
                // Nickname Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nickname (Optional)")
                        .font(AppTheme.fontRounded(size: 11, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                    
                    TextField("Enter nickname", text: $nickname)
                        .font(AppTheme.fontRounded(size: 14))
                        .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(colorScheme == .dark ? AppTheme.darkNavy.opacity(0.6) : AppTheme.paperBeige.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
    
    private var studyPrefsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Preferences / ระดับการเรียน")
                .font(AppTheme.fontSerif(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
            
            // Level Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Japanese Level")
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                
                Picker("Japanese Level", selection: $selectedLevel) {
                    ForEach(levels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .tint(colorScheme == .dark ? Color.white : AppTheme.textDark)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorScheme == .dark ? AppTheme.darkNavy : AppTheme.paperBeige)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1))
            }
            
            // Study Goal Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Study Goal")
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                
                Picker("Study Goal", selection: $studyGoal) {
                    ForEach(goals, id: \.self) { goal in
                        Text(goal).tag(goal)
                    }
                }
                .pickerStyle(.menu)
                .tint(colorScheme == .dark ? Color.white : AppTheme.textDark)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorScheme == .dark ? AppTheme.darkNavy : AppTheme.paperBeige)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1))
                
                // Allow custom input
                TextField("Or enter custom goal...", text: $studyGoal)
                    .font(AppTheme.fontRounded(size: 13))
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colorScheme == .dark ? AppTheme.darkNavy.opacity(0.6) : AppTheme.paperBeige.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1)
                    )
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
}
