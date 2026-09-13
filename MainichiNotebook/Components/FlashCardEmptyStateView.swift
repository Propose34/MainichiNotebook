import SwiftUI

struct FlashCardEmptyStateView: View {
    let onNavigate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.sakuraPinkLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "square.on.square.dashed")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppTheme.sakuraPink)
            }
            
            VStack(spacing: 8) {
                Text("No Flash Cards Yet 🌸")
                    .font(AppTheme.fontSerif(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                
                Text("Add words from the Vocabulary Library to start reviewing them here.")
                    .font(AppTheme.fontRounded(size: 14))
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: onNavigate) {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                    Text("Go to Vocabulary Library")
                }
                .font(AppTheme.fontRounded(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppTheme.sakuraPink)
                .cornerRadius(12)
                .shadow(color: AppTheme.sakuraPink.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(AppTheme.paperCard)
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
    }
}
