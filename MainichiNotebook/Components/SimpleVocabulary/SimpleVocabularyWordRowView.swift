import SwiftUI

struct SimpleVocabularyWordRowView: View {
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
                
                // Japanese word + reading + romaji
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 6) {
                        Text(item.japanese)
                            .font(AppTheme.fontSerif(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                        
                        Text(item.reading)
                            .font(AppTheme.fontSerif(size: 12))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    
                    Text("[\(item.romaji)]")
                        .font(AppTheme.fontRounded(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(width: 140, alignment: .leading)
                
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
                    .font(AppTheme.fontRounded(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textDark)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 6) {
                    // Pronunciation button
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
                            .font(.system(size: 11))
                            .foregroundColor(isAudioPlaying ? AppTheme.sakuraPink : AppTheme.textMuted)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .disabled(isAudioPlaying)
                    
                    // Favorite button
                    let starred = studyUserLibraryService.isFavorite(targetType: .vocabulary, targetId: item.id)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            studyUserLibraryService.toggleFavorite(targetType: .vocabulary, targetId: item.id)
                        }
                    }) {
                        Image(systemName: starred ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(starred ? Color.orange : AppTheme.textMuted)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    // Add to My List button
                    let inMyList = studyUserLibraryService.isInMyList(targetType: .vocabulary, targetId: item.id)
                    Button(action: {
                        withAnimation {
                            studyUserLibraryService.toggleMyList(targetType: .vocabulary, targetId: item.id)
                        }
                    }) {
                        Image(systemName: inMyList ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 11))
                            .foregroundColor(inMyList ? AppTheme.sageGreen : AppTheme.textMuted)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    // Add to Flash Cards button
                    let inFlashcards = studyUserLibraryService.isInFlashcards(targetType: .vocabulary, targetId: item.id)
                    Button(action: {
                        withAnimation {
                            studyUserLibraryService.toggleFlashcardCollection(targetType: .vocabulary, targetId: item.id)
                        }
                    }) {
                        Image(systemName: inFlashcards ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                            .font(.system(size: 11))
                            .foregroundColor(inFlashcards ? AppTheme.sakuraPink : AppTheme.textMuted)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? AppTheme.sakuraPinkLight.opacity(0.3) : AppTheme.paperCard)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? AppTheme.sakuraPink : AppTheme.borderLight, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
