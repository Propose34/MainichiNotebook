import SwiftUI

struct WritingPracticeStatsView: View {
    let mode: WritingPracticeMode
    let totalCount: Int
    let practicedCount: Int
    let todayCount: Int
    let lastChar: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Main progress counter card
            VStack(alignment: .leading, spacing: 2) {
                Text("PROGRESS")
                    .font(AppTheme.fontRounded(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(practicedCount)")
                        .font(AppTheme.fontRounded(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    Text("/ \(totalCount)")
                        .font(AppTheme.fontRounded(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.paperCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.borderLight, lineWidth: 1)
            )
            
            // Today's counter card
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(AppTheme.fontRounded(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                
                Text("\(todayCount)")
                    .font(AppTheme.fontRounded(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.paperCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.borderLight, lineWidth: 1)
            )
            
            // Last practiced character card
            VStack(alignment: .leading, spacing: 2) {
                Text("LAST PRACTICED")
                    .font(AppTheme.fontRounded(size: 8, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                
                if let lastChar = lastChar {
                    Text(lastChar)
                        .font(AppTheme.fontSerif(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.sageGreen)
                } else {
                    Text("Not practiced yet")
                        .font(AppTheme.fontRounded(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.paperCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.borderLight, lineWidth: 1)
            )
        }
    }
}
