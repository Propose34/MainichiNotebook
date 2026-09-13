import SwiftUI

struct EmptyStateCardView: View {
    let iconName: String
    let title: String
    let description: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(AppTheme.sakuraPink)
                .padding(16)
                .background(Circle().fill(AppTheme.sakuraPink.opacity(0.1)))
            
            Text(title)
                .font(AppTheme.titleSmall)
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
            
            Text(description)
                .font(AppTheme.fontRounded(size: 13))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerLG)
                .stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1)
        )
    }
}
