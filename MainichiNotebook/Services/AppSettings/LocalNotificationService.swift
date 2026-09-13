import Foundation
import UserNotifications
import Combine

final class LocalNotificationService: ObservableObject {
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[LocalNotificationService] Error requesting notification auth: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
    
    func scheduleDailyReminder(hour: Int, minute: Int, completion: @escaping (Bool) -> Void = { _ in }) {
        // Cancel existing first
        cancelAllReminders()
        
        let content = UNMutableNotificationContent()
        content.title = "Mainichi Study Time ⛅"
        content.body = "A small Japanese practice session is waiting for you. Let's study together!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "com.mainichi.study_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[LocalNotificationService] Failed to schedule: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("[LocalNotificationService] Scheduled daily reminder for \(String(format: "%02d:%02d", hour, minute))")
                    completion(true)
                }
            }
        }
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["com.mainichi.study_reminder"])
        print("[LocalNotificationService] Cancelled daily study reminder.")
    }
}
