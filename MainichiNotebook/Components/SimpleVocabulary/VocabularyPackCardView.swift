import SwiftUI

struct VocabularyPackCardView: View {
    let pack: SimpleVocabularyPack
    let wordCount: Int
    let savedCount: Int
    let favoriteCount: Int
    let progress: SimpleVocabularyPackProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Emoji, Level Badge
            HStack(alignment: .top) {
                // Emoji Circle
                ZStack {
                    Circle()
                        .fill(AppTheme.sakuraPinkLight.opacity(0.7))
                        .frame(width: 44, height: 44)
                    
                    Text(pack.emoji)
                        .font(.system(size: 22))
                }
                
                Spacer()
                
                // Level Badge
                Text(pack.levelBadge)
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.woodDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.paperBeige)
                    .cornerRadius(6)
            }
            
            // Pack Title & Description
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.title)
                    .font(AppTheme.fontSerif(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                    .lineLimit(1)
                
                Text(pack.description)
                    .font(AppTheme.fontRounded(size: 11))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 32, alignment: .top)
            }
            
            Spacer(minLength: 0)
            
            Divider()
                .padding(.vertical, 2)
            
            // Bottom row: Stat counts & Progress Bar
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Word Count Badge
                    HStack(spacing: 3) {
                        Image(systemName: "character.book.closed")
                            .font(.system(size: 10))
                        Text("\(wordCount)")
                    }
                    
                    // Flashcards count Badge
                    HStack(spacing: 3) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.sakuraPink)
                        Text("\(savedCount)")
                    }
                    
                    // Favorites count Badge
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text("\(favoriteCount)")
                    }
                }
                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
                
                // Progress Bar
                if wordCount > 0 {
                    let pct = Double(progress.viewedWordIds.count) / Double(wordCount)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Spacer()
                            Text("\(progress.viewedWordIds.count)/\(wordCount) seen")
                                .font(AppTheme.fontRounded(size: 9, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppTheme.borderLight)
                                    .frame(height: 5)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppTheme.sakuraPink)
                                    .frame(width: geo.size.width * CGFloat(pct), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
        }
        .padding(16)
        .frame(height: 180)
        .background(AppTheme.paperCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
        .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}
