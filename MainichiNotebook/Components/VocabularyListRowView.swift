import SwiftUI

struct VocabularyListRowView: View {
    let item: VocabularyItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @State private var isAudioPlaying: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selected indicator line
                if isSelected {
                    Rectangle()
                        .fill(AppTheme.sakuraPink)
                        .frame(width: 4)
                        .cornerRadius(2)
                }
                
                // Japanese word + reading
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.japanese)
                        .font(AppTheme.fontSerif(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    Text(item.reading)
                        .font(AppTheme.fontSerif(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(width: 100, alignment: .leading)
                
                // Part of Speech
                Text(item.partOfSpeech)
                    .font(AppTheme.fontRounded(size: 8, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.sakuraPinkLight)
                    .cornerRadius(4)
                
                // Thai Meaning
                Text(item.meaningTh)
                    .font(AppTheme.fontRounded(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textDark)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                // Badges and actions group
                HStack(spacing: 8) {
                    if item.status == "custom" {
                        Text("My Word")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(AppTheme.sakuraPink)
                            .cornerRadius(4)
                    } else if let level = item.level {
                        Text(level)
                            .font(AppTheme.fontRounded(size: 9, weight: .bold))
                            .foregroundColor(AppTheme.woodDark)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(AppTheme.paperBeige)
                            .cornerRadius(4)
                    }
                    
                    // Audio Play
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
                            .font(.system(size: 10))
                            .foregroundColor((item.japanese.isEmpty && item.reading.isEmpty) ? AppTheme.textMuted.opacity(0.3) : (isAudioPlaying ? AppTheme.sakuraPink : AppTheme.textMuted))
                            .frame(width: 22, height: 22)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .disabled(isAudioPlaying || (item.japanese.isEmpty && item.reading.isEmpty))
                    
                    // Favorite Star
                    let starred = studyUserLibraryService.isFavorite(targetType: .vocabulary, targetId: item.id)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            studyUserLibraryService.toggleFavorite(targetType: .vocabulary, targetId: item.id)
                        }
                    }) {
                        Image(systemName: starred ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(starred ? Color.orange : AppTheme.textMuted)
                            .frame(width: 22, height: 22)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isSelected ? AppTheme.sakuraPinkLight.opacity(0.3) : AppTheme.paperCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppTheme.sakuraPink.opacity(0.4) : AppTheme.borderLight, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
