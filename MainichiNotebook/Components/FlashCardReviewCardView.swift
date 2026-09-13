import SwiftUI

struct FlashCardReviewCardView: View {
    let card: ReviewCard
    let isAnswerRevealed: Bool
    let selectedChoice: String?
    let isCorrect: Bool?
    let enablePronunciation: Bool
    let showExampleAfterAnswer: Bool
    let onSelectChoice: (String) -> Void
    let onRevealAnswer: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack {
                    Text(card.mode.rawValue.uppercased())
                        .font(AppTheme.fontRounded(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.sakuraPink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.sakuraPink.opacity(0.15))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    if enablePronunciation {
                        let isEmptyAudio = card.vocabularyItem.japanese.isEmpty && card.vocabularyItem.reading.isEmpty
                        Button(action: {
                            if !isEmptyAudio {
                                let _ = JapanesePronunciationService.shared.speakVocabulary(card.vocabularyItem)
                            }
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isEmptyAudio ? AppTheme.textMuted.opacity(0.3) : AppTheme.sakuraPink)
                                .padding(8)
                                .background(isEmptyAudio ? AppTheme.paperBeige.opacity(0.4) : AppTheme.sakuraPinkLight)
                                .clipShape(Circle())
                        }
                        .disabled(isEmptyAudio)
                    }
                }
                
                VStack(spacing: 8) {
                    Text(card.promptText)
                        .font(card.isMultipleChoice ? AppTheme.fontSerif(size: 26, weight: .bold) : .system(size: 46, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.textDark)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    if let sub = card.promptSubtext, !sub.isEmpty {
                        Text(sub)
                            .font(AppTheme.fontRounded(size: 15))
                            .foregroundColor(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, card.isMultipleChoice ? 12 : 24)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .background(AppTheme.borderLight)
            
            if card.isMultipleChoice {
                VStack(spacing: 12) {
                    ForEach(card.choices) { choice in
                        Button(action: {
                            if selectedChoice == nil {
                                onSelectChoice(choice.id)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(choice.primaryText)
                                        .font(AppTheme.fontRounded(size: 15, weight: .semibold))
                                        .foregroundColor(choiceColor(choice: choice, correctChoiceId: card.correctChoiceId))
                                        .multilineTextAlignment(.leading)
                                    
                                    if let sec = choice.secondaryText {
                                        HStack(spacing: 4) {
                                            Text(sec)
                                                .font(AppTheme.fontRounded(size: 11))
                                                .foregroundColor(AppTheme.textMuted)
                                            if let ter = choice.tertiaryText {
                                                Text("/ \(ter)")
                                                    .font(AppTheme.fontRounded(size: 11))
                                                    .foregroundColor(AppTheme.textMuted)
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                choiceIcon(choice: choice, correctChoiceId: card.correctChoiceId)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(choiceBackgroundColor(choice: choice, correctChoiceId: card.correctChoiceId))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(choiceBorderColor(choice: choice, correctChoiceId: card.correctChoiceId), lineWidth: 1.5)
                            )
                        }
                        .disabled(selectedChoice != nil)
                    }
                }
                
                if isAnswerRevealed {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(card.vocabularyItem.japanese)
                                .font(AppTheme.fontSerif(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            Text("[\(card.vocabularyItem.reading)]")
                                .font(AppTheme.fontRounded(size: 14))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        Text("ความหมาย: \(card.vocabularyItem.meaningTh)")
                            .font(AppTheme.fontRounded(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textDark)
                        
                        if let explanation = card.explanationTh, !explanation.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("คำอธิบาย:")
                                    .font(AppTheme.fontRounded(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                Text(explanation)
                                    .font(AppTheme.fontRounded(size: 13))
                                    .foregroundColor(AppTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            .background(AppTheme.paperBeige)
                            .cornerRadius(8)
                            .padding(.top, 4)
                        }
                        
                        if showExampleAfterAnswer, let exJp = card.vocabularyItem.exampleJp, !exJp.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ตัวอย่างประโยค:")
                                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                Text(exJp)
                                    .font(AppTheme.fontSerif(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textDark)
                                if let exTh = card.vocabularyItem.exampleTh {
                                    Text(exTh)
                                        .font(AppTheme.fontRounded(size: 11))
                                        .foregroundColor(AppTheme.textMuted)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.paperBeige)
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AppTheme.paperBeige.opacity(0.4))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
            } else {
                if !isAnswerRevealed {
                    Button(action: onRevealAnswer) {
                        Text("Reveal Answer")
                            .font(AppTheme.fontRounded(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.darkNavy)
                            .cornerRadius(12)
                            .shadow(color: AppTheme.darkNavy.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    .padding(.vertical, 16)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reading / Romaji")
                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                            
                            Text("\(card.vocabularyItem.reading) (\(card.vocabularyItem.romaji))")
                                .font(AppTheme.fontSerif(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textDark)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Meaning (Thai)")
                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                            
                            Text(card.vocabularyItem.meaningTh)
                                .font(AppTheme.fontRounded(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.sakuraPink)
                        }
                        
                        if showExampleAfterAnswer, let exJp = card.vocabularyItem.exampleJp, !exJp.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Example Sentence")
                                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exJp)
                                        .font(AppTheme.fontSerif(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.textDark)
                                    
                                    if let exTh = card.vocabularyItem.exampleTh, !exTh.isEmpty {
                                        Text(exTh)
                                            .font(AppTheme.fontRounded(size: 12))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.paperBeige)
                                .cornerRadius(10)
                            }
                        }
                        
                        if let notes = card.vocabularyItem.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                
                                Text(notes)
                                    .font(AppTheme.fontRounded(size: 13))
                                    .foregroundColor(AppTheme.textDark)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(AppTheme.paperBeige)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .padding(24)
        .background(AppTheme.paperCard)
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
    }
    
    private func choiceColor(choice: ReviewChoice, correctChoiceId: String) -> Color {
        guard selectedChoice != nil else { return AppTheme.textDark }
        if choice.isCorrect || choice.id == correctChoiceId {
            return AppTheme.sageGreen
        }
        if selectedChoice == choice.id {
            return AppTheme.sakuraPink
        }
        return AppTheme.textMuted
    }
    
    private func choiceBackgroundColor(choice: ReviewChoice, correctChoiceId: String) -> Color {
        guard selectedChoice != nil else { return AppTheme.paperCard }
        if choice.isCorrect || choice.id == correctChoiceId {
            return AppTheme.sageGreenLight
        }
        if selectedChoice == choice.id {
            return AppTheme.sakuraPinkLight
        }
        return AppTheme.paperCard
    }
    
    private func choiceBorderColor(choice: ReviewChoice, correctChoiceId: String) -> Color {
        guard let selected = selectedChoice else { return AppTheme.borderLight }
        if choice.isCorrect || choice.id == correctChoiceId {
            return AppTheme.sageGreen.opacity(0.4)
        }
        if selected == choice.id {
            return AppTheme.sakuraPink.opacity(0.4)
        }
        return AppTheme.borderLight.opacity(0.5)
    }
    
    @ViewBuilder
    private func choiceIcon(choice: ReviewChoice, correctChoiceId: String) -> some View {
        if selectedChoice != nil {
            if choice.isCorrect || choice.id == correctChoiceId {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.sageGreen)
            } else if selectedChoice == choice.id {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.sakuraPink)
            }
        }
    }
}
