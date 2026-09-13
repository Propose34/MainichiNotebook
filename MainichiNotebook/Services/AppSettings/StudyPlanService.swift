import Foundation
import Combine

@MainActor
final class StudyPlanService: ObservableObject {
    @Published var tasks: [String: [StudyPlanTask]] = [:] // dateKey -> tasks
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("study-plans.json")
    }
    
    init() {
        loadTasks()
        seedDefaultTasksIfNeeded()
    }
    
    func loadTasks() {
        let path = fileURL
        guard FileManager.default.fileExists(atPath: path.path) else {
            self.tasks = [:]
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            let decoded = try JSONDecoder().decode([StudyPlanTask].self, from: data)
            var temp: [String: [StudyPlanTask]] = [:]
            for item in decoded {
                temp[item.dateKey, default: []].append(item)
            }
            self.tasks = temp
            print("[StudyPlanService] Loaded plans for \(tasks.count) dates.")
        } catch {
            print("[StudyPlanService] Failed to load plans: \(error.localizedDescription)")
            self.tasks = [:]
        }
    }
    
    func saveTasks() {
        let path = fileURL
        do {
            let flatList = tasks.values.flatMap { $0 }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(flatList)
            try data.write(to: path, options: .atomic)
            print("[StudyPlanService] Saved study plans successfully.")
        } catch {
            print("[StudyPlanService] Failed to save study plans: \(error.localizedDescription)")
        }
    }
    
    func makeDateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    func getTasks(for date: Date) -> [StudyPlanTask] {
        let key = makeDateKey(from: date)
        return tasks[key] ?? []
    }
    
    func getTasks(forDateKey dateKey: String) -> [StudyPlanTask] {
        return tasks[dateKey] ?? []
    }
    
    func addTask(date: Date, title: String, timeString: String) {
        let key = makeDateKey(from: date)
        let newTask = StudyPlanTask(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            timeString: timeString.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: false,
            dateKey: key
        )
        tasks[key, default: []].append(newTask)
        saveTasks()
    }
    
    func toggleTask(id: String, dateKey: String) {
        guard var list = tasks[dateKey] else { return }
        if let idx = list.firstIndex(where: { $0.id == id }) {
            list[idx].isCompleted.toggle()
            tasks[dateKey] = list
            saveTasks()
        }
    }
    
    func deleteTask(id: String, dateKey: String) {
        guard var list = tasks[dateKey] else { return }
        if let idx = list.firstIndex(where: { $0.id == id }) {
            list.remove(at: idx)
            tasks[dateKey] = list
            saveTasks()
        }
    }
    
    private func seedDefaultTasksIfNeeded() {
        let todayKey = makeDateKey(from: Date())
        if tasks[todayKey] == nil || tasks[todayKey]?.isEmpty == true {
            let task1 = StudyPlanTask(id: UUID().uuidString, title: "Lecture: Lesson 12", timeString: "30 min", isCompleted: true, dateKey: todayKey)
            let task2 = StudyPlanTask(id: UUID().uuidString, title: "Vocabulary Study", timeString: "20 min", isCompleted: true, dateKey: todayKey)
            let task3 = StudyPlanTask(id: UUID().uuidString, title: "Writing Practice", timeString: "15 min", isCompleted: false, dateKey: todayKey)
            tasks[todayKey] = [task1, task2, task3]
            saveTasks()
        }
    }
}
