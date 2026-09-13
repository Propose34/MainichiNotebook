import SwiftUI

enum MainCategory: String, CaseIterable, Identifiable {
    case home = "Home"
    case lectures = "Lectures"
    case vocabularyLibrary = "Vocabulary Library"
    case writingPractice = "Writing Practice"
    case simpleVocabulary = "Simple Vocabulary"
    case dailySummary = "Daily Summary"
    case flashCards = "Flash Cards"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .lectures: return "play.square.fill"
        case .vocabularyLibrary: return "book.fill"
        case .writingPractice: return "pencil"
        case .simpleVocabulary: return "character.square.fill"
        case .dailySummary: return "doc.text.fill"
        case .flashCards: return "square.on.square.fill"
        }
    }
    
    var thaiPlaceholderTitle: String {
        switch self {
        case .vocabularyLibrary: return "คลังคำศัพท์"
        case .writingPractice: return "ฝึกเขียนคัดลายมือ"
        case .simpleVocabulary: return "คำศัพท์พื้นฐาน"
        case .dailySummary: return "สรุปบทเรียนรายวัน"
        case .flashCards: return "บัตรคำศัพท์"
        default: return ""
        }
    }
}

struct SidebarView: View {
    @Binding var selectedCategory: MainCategory
    @Binding var isCollapsed: Bool
    var onSettingTap: () -> Void
    var onThemeTap: () -> Void
    
    var body: some View {
        VStack(spacing: isCollapsed ? 16 : 20) {
            // Collapse/Expand toggle button at the top
            HStack {
                if !isCollapsed {
                    Spacer()
                }
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isCollapsed.toggle()
                    }
                }) {
                    Image(systemName: isCollapsed ? "sidebar.right" : "sidebar.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.paperBeige.opacity(0.85))
                        .padding(8)
                        .background(Circle().fill(AppTheme.paperBeige.opacity(0.06)))
                }
                if isCollapsed {
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)

            // Logo Header
            if !isCollapsed {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "D8C090").opacity(0.45), lineWidth: 1.5)
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .stroke(Color(hex: "D8C090").opacity(0.7), lineWidth: 0.8)
                            .frame(width: 66, height: 66)
                        
                        VStack(spacing: 2) {
                            Image(systemName: "laurel.leading")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.sakuraPink)
                                .offset(x: -8)
                            
                            // Sakura symbol and open book overlapping
                            ZStack {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.paperBeige)
                                    .offset(y: 4)
                                
                                Image(systemName: "flower.turtle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.sakuraPink)
                                    .offset(y: -4)
                            }
                        }
                    }
                    
                    Text("毎日ノート")
                        .font(AppTheme.fontSerif(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.paperBackground)
                        .tracking(2)
                    
                    Text("Mainichi Notebook")
                        .font(AppTheme.fontRounded(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.paperBackground.opacity(0.5))
                }
                .padding(.bottom, 12)
            } else {
                // Shrunk logo for collapsed mode
                Image(systemName: "flower.turtle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.sakuraPink)
                    .padding(.bottom, 8)
            }
            
            // Category Buttons List
            VStack(spacing: 8) {
                ForEach(MainCategory.allCases) { category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }) {
                        if isCollapsed {
                            // Centered Icon only
                            ZStack {
                                if category == .simpleVocabulary {
                                    Text("あ")
                                        .font(AppTheme.fontSerif(size: 14, weight: .bold))
                                        .frame(width: 36, height: 36)
                                        .background(selectedCategory == category ? AppTheme.paperBeige : AppTheme.paperBeige.opacity(0.1))
                                        .foregroundColor(selectedCategory == category ? AppTheme.darkNavy : AppTheme.paperBeige)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: category.iconName)
                                        .font(.system(size: 18))
                                        .foregroundColor(selectedCategory == category ? AppTheme.darkNavy : AppTheme.paperBeige)
                                        .frame(width: 36, height: 36)
                                        .background(selectedCategory == category ? AppTheme.paperBeige : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .frame(width: 44, height: 44)
                        } else {
                            // Icon + Text
                            HStack(spacing: 12) {
                                if category == .simpleVocabulary {
                                    // Customized Hiragana "あ" box for simple vocab
                                    Text("あう")
                                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                                        .frame(width: 22, height: 22)
                                        .background(selectedCategory == category ? AppTheme.darkNavy : AppTheme.paperBeige.opacity(0.1))
                                        .foregroundColor(selectedCategory == category ? AppTheme.paperBackground : AppTheme.paperBeige)
                                        .cornerRadius(4)
                                } else {
                                    Image(systemName: category.iconName)
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedCategory == category ? AppTheme.darkNavy : AppTheme.paperBeige)
                                        .frame(width: 22)
                                }
                                
                                Text(category.rawValue)
                                    .font(AppTheme.fontRounded(size: 14, weight: selectedCategory == category ? .bold : .medium))
                                    .foregroundColor(selectedCategory == category ? AppTheme.darkNavy : AppTheme.paperBeige)
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                selectedCategory == category ?
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.paperBeige) : nil
                            )
                        }
                    }
                    .padding(.horizontal, isCollapsed ? 4 : 12)
                }
            }
            
            Spacer()
            
            // Consistency Card
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("継続は力なり。")
                            .font(AppTheme.fontSerif(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.sakuraPink)
                        Spacer()
                        // Small branch decoration
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.sakuraPink.opacity(0.6))
                    }
                    
                    Text("Keizoku wa chikara nari.")
                        .font(AppTheme.fontRounded(size: 10, weight: .light))
                        .foregroundColor(AppTheme.paperBackground.opacity(0.7))
                    
                    Text("— Consistency is power.")
                        .font(AppTheme.fontRounded(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.paperBackground.opacity(0.9))
                        .padding(.top, 2)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.paperBeige.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.sakuraPink.opacity(0.2), lineWidth: 0.8)
                        )
                )
                .padding(.horizontal, 16)
            }
            
            // Bottom Action Row (Settings & Night mode)
            Group {
                if isCollapsed {
                    VStack(spacing: 12) {
                        Button(action: onSettingTap) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.paperBeige.opacity(0.8))
                                .padding(10)
                                .background(Circle().fill(AppTheme.paperBeige.opacity(0.06)))
                        }
                        
                        Button(action: onThemeTap) {
                            Image(systemName: "moon")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.paperBeige.opacity(0.8))
                                .padding(10)
                                .background(Circle().fill(AppTheme.paperBeige.opacity(0.06)))
                        }
                    }
                    .padding(.bottom, 16)
                } else {
                    HStack {
                        Button(action: onSettingTap) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.paperBeige.opacity(0.8))
                                .padding(10)
                                .background(Circle().fill(AppTheme.paperBeige.opacity(0.06)))
                        }
                        
                        Spacer()
                        
                        Button(action: onThemeTap) {
                            Image(systemName: "moon")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.paperBeige.opacity(0.8))
                                .padding(10)
                                .background(Circle().fill(AppTheme.paperBeige.opacity(0.06)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: isCollapsed ? 70 : 250)
        .background(AppTheme.darkNavy)
    }
}
