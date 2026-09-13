import SwiftUI

struct WritingModeSegmentedControl: View {
    @Binding var selectedMode: WritingPracticeMode
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(WritingPracticeMode.allCases) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                }) {
                    Text(mode.rawValue)
                        .font(AppTheme.fontRounded(size: 14, weight: .bold))
                        .foregroundColor(selectedMode == mode ? AppTheme.textDark : AppTheme.textMuted)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selectedMode == mode {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppTheme.paperCard)
                                        .shadow(color: AppTheme.shadowColor, radius: 2)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(AppTheme.paperBeige)
        .cornerRadius(10)
    }
}
