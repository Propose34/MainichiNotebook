import SwiftUI

struct FlashCardSetupOptionsView: View {
    @Binding var options: FlashCardReviewOptions
    let availableCardsCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(AppTheme.sakuraPink)
                Text("Practice Settings")
                    .font(AppTheme.fontSerif(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
            }
            .padding(.horizontal, 4)
            
            Divider()
                .background(AppTheme.borderLight)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Question Mode")
                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                
                ForEach(FlashCardQuestionMode.allCases) { mode in
                    Button(action: {
                        options.questionMode = mode
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(AppTheme.fontRounded(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textDark)
                                Text(mode.labelTh)
                                    .font(AppTheme.fontRounded(size: 11))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            Spacer()
                            if options.questionMode == mode {
                                Image(systemName: "largecircle.fill.circle")
                                    .foregroundColor(options.source.themeColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(AppTheme.borderLight)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(options.questionMode == mode ? options.source.themeColor.opacity(0.08) : AppTheme.paperCard)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(options.questionMode == mode ? options.source.themeColor.opacity(0.4) : AppTheme.borderLight, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Divider()
                .background(AppTheme.borderLight)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Display Options")
                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                
                Group {
                    Toggle(isOn: $options.showReading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Reading")
                                .font(AppTheme.fontRounded(size: 14, weight: .bold))
                            Text("แสดงคำอ่านฮิรางานะใต้คำศัพท์")
                                .font(AppTheme.fontRounded(size: 11))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: options.source.themeColor))
                    
                    Toggle(isOn: $options.showRomaji) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Romaji")
                                .font(AppTheme.fontRounded(size: 14, weight: .bold))
                            Text("แสดงตัวโรมาจิช่วยสะกดภาษาอังกฤษ")
                                .font(AppTheme.fontRounded(size: 11))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: options.source.themeColor))
                    
                    Toggle(isOn: $options.showRomajiInChoices) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Romaji in Choices")
                                .font(AppTheme.fontRounded(size: 14, weight: .bold))
                            Text("แสดงเสียงสะกดบนกล่องตัวเลือกเพื่อช่วยจำ")
                                .font(AppTheme.fontRounded(size: 11))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: options.source.themeColor))
                    
                    Toggle(isOn: $options.showExampleAfterAnswer) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Example Sentence")
                                .font(AppTheme.fontRounded(size: 14, weight: .bold))
                            Text("แสดงประโยคตัวอย่างหลังตอบคำถามเสร็จ")
                                .font(AppTheme.fontRounded(size: 11))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: options.source.themeColor))
                    
                    Toggle(isOn: $options.enablePronunciation) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Pronunciation Button")
                                .font(AppTheme.fontRounded(size: 14, weight: .bold))
                            Text("เปิดปุ่มกดฟังเสียงอ่านคำศัพท์ (ja-JP)")
                                .font(AppTheme.fontRounded(size: 11))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: options.source.themeColor))
                }
            }
            
            Divider()
                .background(AppTheme.borderLight)
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Session Options")
                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of Cards")
                        .font(AppTheme.fontRounded(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textDark)
                    
                    HStack(spacing: 8) {
                        ForEach([5, 10, 20, 9999], id: \.self) { limit in
                            let label = limit == 9999 ? "All (\(availableCardsCount))" : "\(limit)"
                            let isLimitSelected = (options.cardLimit == limit) || (limit == 9999 && options.cardLimit >= availableCardsCount)
                            
                            Button(action: {
                                options.cardLimit = limit
                            }) {
                                Text(label)
                                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                    .foregroundColor(isLimitSelected ? .white : AppTheme.textDark)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(isLimitSelected ? options.source.themeColor : AppTheme.paperCard)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isLimitSelected ? options.source.themeColor : AppTheme.borderLight, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Toggle(isOn: $options.shuffle) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shuffle Cards")
                            .font(AppTheme.fontRounded(size: 14, weight: .bold))
                        Text("สลับลำดับการ์ดแบบสุ่มทบทวน")
                            .font(AppTheme.fontRounded(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: options.source.themeColor))
            }
        }
        .padding(20)
        .background(AppTheme.paperCard)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
    }
}
