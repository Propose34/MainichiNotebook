import SwiftUI

struct VocabularyCardView: View {
    let item: VocabularyItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @State private var isAudioPlaying: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Top row: Level badge & Action buttons
                HStack {
                    if item.status == "custom" {
                        Text("My Word")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(AppTheme.sakuraPink)
                            .cornerRadius(4)
                    } else if let level = item.level {
                        Text(level)
                            .font(AppTheme.fontRounded(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.woodDark)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.paperBeige)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Audio Play Indicator
                    Button(action: {
                        let success = JapanesePronunciationService.shared.speakVocabulary(item)
                        if success {
                            isAudioPlaying = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                isAudioPlaying = false
                            }
                        }
                    }) {
                        Image(systemName: isAudioPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor((item.japanese.isEmpty && item.reading.isEmpty) ? AppTheme.textMuted.opacity(0.3) : (isAudioPlaying ? AppTheme.sakuraPink : AppTheme.textMuted))
                            .frame(width: 24, height: 24)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .disabled(isAudioPlaying || (item.japanese.isEmpty && item.reading.isEmpty))
                    
                    // Favorite button
                    let starred = studyUserLibraryService.isFavorite(targetType: .vocabulary, targetId: item.id)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            studyUserLibraryService.toggleFavorite(targetType: .vocabulary, targetId: item.id)
                        }
                    }) {
                        Image(systemName: starred ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(starred ? Color.orange : AppTheme.textMuted)
                            .frame(width: 24, height: 24)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                
                // Japanese text
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.japanese)
                        .font(AppTheme.fontSerif(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(item.reading)
                        .font(AppTheme.fontSerif(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                        .lineLimit(1)
                }
                
                // Thai Meaning
                Text(item.meaningTh)
                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
                
                // Bottom row: Part of Speech badge
                Text(item.partOfSpeech)
                    .font(AppTheme.fontRounded(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.sakuraPinkLight)
                    .cornerRadius(6)
            }
            .padding(12)
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppTheme.sakuraPinkLight.opacity(0.3) : AppTheme.paperCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.sakuraPink : AppTheme.borderLight, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
