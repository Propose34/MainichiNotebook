import SwiftUI

struct FlashCardProgressBarView: View {
    let progress: Double
    let color: Color
    var correctCount: Int? = nil
    var totalCount: Int
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Session Progress")
                    .font(AppTheme.fontRounded(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                
                Spacer()
                
                if let correct = correctCount {
                    Text("\(correct) correct / \(totalCount) total")
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                } else {
                    let percentage = Int(progress * 100)
                    Text("\(percentage)%")
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.paperBeige)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(0, min(geometry.size.width * CGFloat(progress), geometry.size.width)), height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}
