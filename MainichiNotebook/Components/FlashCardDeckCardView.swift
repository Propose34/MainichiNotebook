import SwiftUI

struct FlashCardDeckCardView: View {
    let source: ReviewSource
    let cardCount: Int
    let promptCount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(source.themeColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: source.iconName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(source.themeColor)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(source.themeColor)
                            .font(.title3)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.rawValue)
                        .font(AppTheme.fontSerif(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text(source.description)
                        .font(AppTheme.fontRounded(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 36, alignment: .topLeading)
                }
                
                Divider()
                    .background(AppTheme.borderLight)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "character.book.closed")
                            .font(.caption)
                            .foregroundColor(AppTheme.textMuted)
                        Text("\(cardCount) words")
                            .font(AppTheme.fontRounded(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textDark)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.bubble")
                            .font(.caption)
                            .foregroundColor(AppTheme.textMuted)
                        Text("\(promptCount) prompts")
                            .font(AppTheme.fontRounded(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textDark)
                    }
                }
            }
            .padding(18)
            .background(AppTheme.paperCard)
            .cornerRadius(16)
            .shadow(color: isSelected ? source.themeColor.opacity(0.12) : AppTheme.shadowColor, radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? source.themeColor.opacity(0.5) : AppTheme.borderLight, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
