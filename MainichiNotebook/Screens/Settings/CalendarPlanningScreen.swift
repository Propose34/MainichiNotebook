import SwiftUI

struct CalendarPlanningScreen: View {
    @EnvironmentObject private var planService: StudyPlanService
    @EnvironmentObject private var settingsService: AppSettingsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedDate = Date()
    @State private var newTaskTitle = ""
    @State private var newTaskTime = "30 min"
    
    private var activeColorScheme: ColorScheme? {
        switch settingsService.settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    private var dateKey: String {
        planService.makeDateKey(from: selectedDate)
    }
    
    private var activeTasks: [StudyPlanTask] {
        planService.getTasks(forDateKey: dateKey)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Graphical Calendar Picker
                        calendarCard
                        
                        // Tasks for Selected Date
                        tasksCard
                    }
                    .padding(16)
                }
            }
            .background(colorScheme == .dark ? AppTheme.darkNavy : AppTheme.paperBackground)
            .navigationTitle("Study Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(AppTheme.fontRounded(size: 15, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                }
            }
            .preferredColorScheme(activeColorScheme)
        }
    }
    
    // MARK: - Subviews
    
    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Date / เลือกวันทบทวน")
                .font(AppTheme.fontSerif(size: 15, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                .padding(.horizontal, 4)
            
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .accentColor(AppTheme.sakuraPink)
            .padding(10)
            .background(colorScheme == .dark ? AppTheme.darkNavy : AppTheme.paperBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1))
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadowColor, radius: 4)
    }
    
        private var tasksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Plan for \(formattedDate)")
                    .font(AppTheme.fontSerif(size: 16, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                Spacer()
                Text("\(activeTasks.count) tasks")
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
            }
            
            // Add Task Form Inline
            HStack(spacing: 8) {
                TextField("e.g. ส่งการบ้าน N5 / Submit homework", text: $newTaskTitle)
                    .font(AppTheme.fontRounded(size: 13))
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(colorScheme == .dark ? AppTheme.darkNavy.opacity(0.6) : AppTheme.paperBeige.opacity(0.4))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1))
                
                TextField("Duration", text: $newTaskTime)
                    .font(AppTheme.fontRounded(size: 13))
                    .foregroundColor(colorScheme == .dark ? Color.white : AppTheme.textDark)
                    .frame(width: 80)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(colorScheme == .dark ? AppTheme.darkNavy.opacity(0.6) : AppTheme.paperBeige.opacity(0.4))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1))
                
                Button(action: addTask) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.sakuraPink)
                        .clipShape(Circle())
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.bottom, 8)
            
            // Task List
            if activeTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 32))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.3) : AppTheme.textMuted.opacity(0.4))
                    Text("No plans scheduled for this day.\nไม่มีกิจกรรมการเรียนในวันนี้")
                        .font(AppTheme.fontRounded(size: 12))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(activeTasks) { task in
                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation {
                                    planService.toggleTask(id: task.id, dateKey: dateKey)
                                }
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(task.isCompleted ? AppTheme.sageGreen : (colorScheme == .dark ? Color.white.opacity(0.4) : AppTheme.textMuted.opacity(0.4)))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(AppTheme.fontRounded(size: 14, weight: .bold))
                                    .foregroundColor(task.isCompleted ? (colorScheme == .dark ? Color.white.opacity(0.5) : AppTheme.textMuted) : (colorScheme == .dark ? Color.white : AppTheme.textDark))
                                    .strikethrough(task.isCompleted)
                                
                                Text(task.timeString)
                                    .font(AppTheme.fontRounded(size: 11))
                                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : AppTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    planService.deleteTask(id: task.id, dateKey: dateKey)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.red.opacity(0.8))
                                    .padding(6)
                                    .background(Circle().fill(Color.red.opacity(0.1)))
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(colorScheme == .dark ? AppTheme.darkNavy.opacity(0.4) : AppTheme.paperBeige.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.borderLight, lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.paperCard)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadowColor, radius: 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        planService.addTask(date: selectedDate, title: newTaskTitle, timeString: newTaskTime)
        newTaskTitle = ""
        newTaskTime = "30 min"
    }
}
