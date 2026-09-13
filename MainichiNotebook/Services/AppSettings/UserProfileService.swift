import Foundation
import Combine
import SwiftUI

@MainActor
final class UserProfileService: ObservableObject {
    @Published var profile: UserProfile
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("user-profile.json")
    }
    
    private var profileDirURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        let profileDir = directoryURL.appendingPathComponent("Profile", isDirectory: true)
        try? FileManager.default.createDirectory(at: profileDir, withIntermediateDirectories: true)
        return profileDir
    }
    
    var customAvatarURL: URL {
        return profileDirURL.appendingPathComponent("avatar.jpg")
    }
    
    init() {
        // Fallback default profile
        let now = Date()
        let defaultProfile = UserProfile(
            id: UUID().uuidString,
            displayName: "Sakura",
            nickname: "さくら",
            studyGoal: "Prepare for JLPT N5",
            japaneseLevel: "Beginner",
            avatarImageFileName: "preset_cherry", // Default preset avatar
            createdAt: now,
            updatedAt: now
        )
        
        self.profile = defaultProfile
        loadProfile()
    }
    
    func loadProfile() {
        let path = fileURL
        guard FileManager.default.fileExists(atPath: path.path) else {
            saveProfile()
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
            self.profile = decoded
            print("[UserProfileService] Loaded profile: \(profile.displayName)")
        } catch {
            print("[UserProfileService] Failed to load profile, using defaults: \(error.localizedDescription)")
        }
    }
    
    func saveProfile() {
        let path = fileURL
        do {
            profile.updatedAt = Date()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profile)
            try data.write(to: path, options: .atomic)
            print("[UserProfileService] Saved profile successfully.")
        } catch {
            print("[UserProfileService] Failed to save profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update Actions
    
    func updateProfile(displayName: String, nickname: String?, studyGoal: String?, japaneseLevel: String?) {
        profile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sakura" : displayName
        profile.nickname = nickname
        profile.studyGoal = studyGoal
        profile.japaneseLevel = japaneseLevel
        saveProfile()
    }
    
    func updatePresetAvatar(name: String) {
        profile.avatarImageFileName = name
        // If switching to preset, delete custom avatar file if it exists to clean up
        let customPath = customAvatarURL.path
        if FileManager.default.fileExists(atPath: customPath) {
            try? FileManager.default.removeItem(atPath: customPath)
        }
        saveProfile()
    }
    
    func saveCustomAvatar(imageData: Data) {
        let customPath = customAvatarURL
        do {
            try imageData.write(to: customPath, options: .atomic)
            profile.avatarImageFileName = "avatar.jpg"
            saveProfile()
            print("[UserProfileService] Saved custom avatar image.")
        } catch {
            print("[UserProfileService] Failed to save custom avatar image: \(error.localizedDescription)")
        }
    }
    
    func removeAvatar() {
        let customPath = customAvatarURL.path
        if FileManager.default.fileExists(atPath: customPath) {
            try? FileManager.default.removeItem(atPath: customPath)
        }
        profile.avatarImageFileName = nil
        saveProfile()
    }
}
