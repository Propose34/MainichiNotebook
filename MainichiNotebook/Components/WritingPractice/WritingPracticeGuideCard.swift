import SwiftUI

struct WritingPracticeGuideCard: View {
    @State private var isCollapsed: Bool = UserDefaults.standard.bool(forKey: "dismissed_writing_practice_guide")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Toggle Bar
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isCollapsed.toggle()
                    UserDefaults.standard.set(isCollapsed, forKey: "dismissed_writing_practice_guide")
                }
            }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(AppTheme.sakuraPink)
                        .font(.system(size: 16))
                    
                    Text("How to Practice Writing")
                        .font(AppTheme.fontRounded(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    
                    Spacer()
                    
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.paperCard)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Collapsible Content
            if !isCollapsed {
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    // 6 Numbered Steps
                    VStack(alignment: .leading, spacing: 6) {
                        stepRow(num: 1, text: "Choose Hiragana, Katakana, or Kanji.")
                        stepRow(num: 2, text: "Select a character from the left grid.")
                        stepRow(num: 3, text: "Tap the speaker to hear its natural sound.")
                        stepRow(num: 4, text: "Turn on the Trace Guide to overlay a faint outline.")
                        stepRow(num: 5, text: "Write inside the guided workbook cells.")
                        stepRow(num: 6, text: "Tap Save Practice to commit progress to memory.")
                    }
                    
                    // Tip box
                    HStack(alignment: .top, spacing: 8) {
                        Text("💡")
                            .font(.system(size: 14))
                        Text("Start by tracing the faint character, then try again without the guide.")
                            .font(AppTheme.fontRounded(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textDark.opacity(0.8))
                            .lineSpacing(2)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.sakuraPinkLight)
                    .cornerRadius(8)
                }
                .padding(16)
                .background(AppTheme.paperCard)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.borderLight, lineWidth: 1.5)
        )
        .shadow(color: AppTheme.shadowColor, radius: 4)
    }
    
    private func stepRow(num: Int, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(num).")
                .font(AppTheme.fontRounded(size: 12, weight: .bold))
                .foregroundColor(AppTheme.sakuraPink)
                .frame(width: 16, alignment: .leading)
            
            Text(text)
                .font(AppTheme.fontRounded(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .lineLimit(2)
        }
    }
}
