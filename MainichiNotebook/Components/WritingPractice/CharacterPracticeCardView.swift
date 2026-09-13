import SwiftUI

struct CharacterPracticeCardView: View {
    let character: WritingPracticeCharacter
    let isSelected: Bool
    let practiceCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Text(character.character)
                        .font(AppTheme.fontSerif(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .frame(width: 60, height: 60)
                        .background(isSelected ? AppTheme.sakuraPinkLight : AppTheme.paperBeige.opacity(0.4))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? AppTheme.sakuraPink : AppTheme.borderLight, lineWidth: isSelected ? 2 : 1)
                        )
                    
                    if practiceCount > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.sageGreen)
                            .background(Color.white.clipShape(Circle()))
                            .offset(x: 4, y: -4)
                    }
                }
                
                Text(character.reading)
                    .font(AppTheme.fontRounded(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(1)
            }
            .padding(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
