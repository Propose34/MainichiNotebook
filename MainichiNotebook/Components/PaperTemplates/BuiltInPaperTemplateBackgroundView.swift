import SwiftUI

/// Router component that renders the appropriate vector design for built-in study sheets.
struct BuiltInPaperTemplateBackgroundView: View {
    let presetId: String
    
    var body: some View {
        ZStack {
            Color.white // White base paper background
            
            switch presetId {
            case "blank":
                Color.clear
            case "ruled":
                RuledPaperView(spacing: 26)
            case "grid":
                GridPaperView(spacing: 22)
            case "dotGrid":
                DotGridPaperView(spacing: 22)
            case "genkouYoushi":
                GenkouYoushiView()
            case "kana":
                KanaPracticeView()
            case "kanji":
                KanjiPracticeView()
            case "vocabTable":
                JapaneseVocabularyTableTemplateView()
            case "simpleVocab":
                SimpleVocabularySheetTemplateView()
            case "kanjiStudy":
                KanjiStudySheetTemplateView()
            case "grammarPattern":
                GrammarPatternTemplateView()
            case "sentencePractice":
                SentencePracticeTemplateView()
            case "lessonSummary":
                LessonSummaryTemplateView()
            case "cornellNotes":
                CornellNotesTemplateView()
            case "dailyPlanner":
                DailyJapanesePlannerTemplateView()
            default:
                Color.clear
            }
        }
        .allowsHitTesting(false) // Never capture touches
    }
}

// MARK: - 1. Japanese Vocabulary Table
struct JapaneseVocabularyTableTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let topPadding: CGFloat = 50
            let rowSpacing: CGFloat = 36
            let col1 = w * 0.25
            let col2 = w * 0.50
            let col3 = w * 0.75
            
            ZStack(alignment: .topLeading) {
                // Main Header Title
                HStack {
                    Text("JAPANESE VOCABULARY TABLE  /  ตารางคำศัพท์ภาษาญี่ปุ่น")
                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                // Column headers
                HStack(spacing: 0) {
                    Text("Japanese / ภาษาญี่ปุ่น").frame(width: col1, alignment: .center)
                    Text("Reading / คำอ่าน").frame(width: col1, alignment: .center)
                    Text("Thai Meaning / ความหมาย").frame(width: col1, alignment: .center)
                    Text("Notes / บันทึก").frame(width: col1, alignment: .center)
                }
                .font(AppTheme.fontRounded(size: 9, weight: .bold))
                .foregroundColor(AppTheme.textMuted.opacity(0.7))
                .padding(.top, topPadding - 12)
                
                // Table lines (Grid)
                Path { path in
                    // Vertical dividers
                    path.move(to: CGPoint(x: col1, y: topPadding))
                    path.addLine(to: CGPoint(x: col1, y: h - 20))
                    
                    path.move(to: CGPoint(x: col2, y: topPadding))
                    path.addLine(to: CGPoint(x: col2, y: h - 20))
                    
                    path.move(to: CGPoint(x: col3, y: topPadding))
                    path.addLine(to: CGPoint(x: col3, y: h - 20))
                    
                    // Horizontal rows
                    var y = topPadding
                    while y < h - 20 {
                        path.move(to: CGPoint(x: 16, y: y))
                        path.addLine(to: CGPoint(x: w - 16, y: y))
                        y += rowSpacing
                    }
                    // Bottom border line
                    path.move(to: CGPoint(x: 16, y: h - 20))
                    path.addLine(to: CGPoint(x: w - 16, y: h - 20))
                }
                .stroke(AppTheme.sageGreen.opacity(0.18), lineWidth: 0.8)
            }
        }
    }
}

// MARK: - 2. Simple Vocabulary Sheet
struct SimpleVocabularySheetTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let topPadding: CGFloat = 50
            let rowSpacing: CGFloat = 36
            
            let col1 = w * 0.20
            let col2 = w * 0.40
            let col3 = w * 0.55
            let col4 = w * 0.76
            
            ZStack(alignment: .topLeading) {
                // Header Title
                HStack {
                    Text("SIMPLE VOCABULARY STUDY  /  แผ่นจดคำศัพท์ทั่วไป")
                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                // Column headers
                HStack(spacing: 0) {
                    Text("Word / คำศัพท์").frame(width: col1, alignment: .center)
                    Text("Reading / คำอ่าน").frame(width: col1, alignment: .center)
                    Text("Romaji").frame(width: col3 - col2, alignment: .center)
                    Text("Meaning / ความหมาย").frame(width: col4 - col3, alignment: .center)
                    Text("Example / ประโยคตัวอย่าง").frame(width: w - col4, alignment: .center)
                }
                .font(AppTheme.fontRounded(size: 9, weight: .bold))
                .foregroundColor(AppTheme.textMuted.opacity(0.7))
                .padding(.top, topPadding - 12)
                
                Path { path in
                    // Vertical dividers
                    path.move(to: CGPoint(x: col1, y: topPadding))
                    path.addLine(to: CGPoint(x: col1, y: h - 20))
                    
                    path.move(to: CGPoint(x: col2, y: topPadding))
                    path.addLine(to: CGPoint(x: col2, y: h - 20))
                    
                    path.move(to: CGPoint(x: col3, y: topPadding))
                    path.addLine(to: CGPoint(x: col3, y: h - 20))
                    
                    path.move(to: CGPoint(x: col4, y: topPadding))
                    path.addLine(to: CGPoint(x: col4, y: h - 20))
                    
                    // Horizontal rows
                    var y = topPadding
                    while y < h - 20 {
                        path.move(to: CGPoint(x: 16, y: y))
                        path.addLine(to: CGPoint(x: w - 16, y: y))
                        y += rowSpacing
                    }
                    path.move(to: CGPoint(x: 16, y: h - 20))
                    path.addLine(to: CGPoint(x: w - 16, y: h - 20))
                }
                .stroke(AppTheme.sageGreen.opacity(0.18), lineWidth: 0.8)
            }
        }
    }
}

// MARK: - 3. Kanji Study Sheet
struct KanjiStudySheetTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let midX = w * 0.44
            
            ZStack(alignment: .topLeading) {
                // Header
                HStack {
                    Text("KANJI STUDY SHEET  /  ใบฝึกคัดคันจิ")
                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                // Dividers
                Path { path in
                    // Vertical Split Divider
                    path.move(to: CGPoint(x: midX, y: 44))
                    path.addLine(to: CGPoint(x: midX, y: h - 20))
                }
                .stroke(AppTheme.sakuraPink.opacity(0.25), lineWidth: 1.2)
                
                // Left Column: Main big box + readings
                VStack(alignment: .leading, spacing: 14) {
                    Text("Main Kanji / ตัวอักษรคันจิ")
                        .font(AppTheme.fontRounded(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    
                    // Big Box
                    ZStack {
                        Rectangle()
                            .stroke(AppTheme.sageGreen.opacity(0.2), lineWidth: 1.5)
                            .frame(width: 140, height: 140)
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 70))
                            path.addLine(to: CGPoint(x: 140, y: 70))
                            
                            path.move(to: CGPoint(x: 70, y: 0))
                            path.addLine(to: CGPoint(x: 70, y: 140))
                        }
                        .stroke(AppTheme.sageGreen.opacity(0.12), style: StrokeStyle(lineWidth: 0.7, dash: [4, 4]))
                        .frame(width: 140, height: 140)
                    }
                    .padding(.bottom, 6)
                    
                    // Onyomi
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Onyomi (Chinese reading) / 音読み")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        linePlaceholder
                    }
                    
                    // Kunyomi
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kunyomi (Japanese reading) / 訓読み")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        linePlaceholder
                    }
                    
                    // Meaning
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Meaning / ความหมาย")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        linePlaceholder
                        linePlaceholder
                    }
                }
                .padding(.leading, 24)
                .padding(.top, 54)
                
                // Right Column: Grid and Words
                VStack(alignment: .leading, spacing: 14) {
                    Text("Stroke Practice / ฝึกคัดทีละเส้น")
                        .font(AppTheme.fontRounded(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    
                    // Kanji grid of 6 boxes (2 rows of 3)
                    GridPracticeShelf(rows: 2, cols: 3, boxSize: 64)
                        .padding(.bottom, 10)
                    
                    Text("Example Words & Sentences / คำศัพท์และตัวอย่าง")
                        .font(AppTheme.fontRounded(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    
                    // Lined examples space
                    VStack(spacing: 16) {
                        linePlaceholder
                        linePlaceholder
                        linePlaceholder
                        linePlaceholder
                        linePlaceholder
                        linePlaceholder
                        linePlaceholder
                    }
                }
                .padding(.leading, midX + 18)
                .padding(.trailing, 20)
                .padding(.top, 54)
            }
        }
    }
    
    private var linePlaceholder: some View {
        Rectangle()
            .fill(AppTheme.sageGreen.opacity(0.12))
            .frame(height: 0.8)
    }
}

struct GridPracticeShelf: View {
    let rows: Int
    let cols: Int
    let boxSize: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 8) {
                    ForEach(0..<cols, id: \.self) { _ in
                        ZStack {
                            Rectangle()
                                .stroke(AppTheme.sageGreen.opacity(0.18), lineWidth: 1)
                                .frame(width: boxSize, height: boxSize)
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: boxSize / 2))
                                p.addLine(to: CGPoint(x: boxSize, y: boxSize / 2))
                                p.move(to: CGPoint(x: boxSize / 2, y: 0))
                                p.addLine(to: CGPoint(x: boxSize / 2, y: boxSize))
                            }
                            .stroke(AppTheme.sageGreen.opacity(0.08), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            .frame(width: boxSize, height: boxSize)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 4. Grammar Pattern Sheet
struct GrammarPatternTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            
            ZStack(alignment: .topLeading) {
                // Header
                HStack {
                    Text("GRAMMAR STUDY SHEET  /  ใบสรุปไวยากรณ์")
                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Pattern & Meaning row
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Grammar Pattern / โครงสร้างไวยากรณ์")
                                .font(AppTheme.fontRounded(size: 8, weight: .bold))
                                .foregroundColor(AppTheme.textMuted.opacity(0.6))
                            boxArea(height: 38)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Meaning / ความหมาย")
                                .font(AppTheme.fontRounded(size: 8, weight: .bold))
                                .foregroundColor(AppTheme.textMuted.opacity(0.6))
                            boxArea(height: 38)
                        }
                    }
                    
                    // Structure / Rule
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Connection Rules & Structure / วิธีเชื่อมรูปประโยคและหลักไวยากรณ์")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        boxArea(height: 120)
                    }
                    
                    // Example Sentences
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Example Sentences / ประโยคตัวอย่าง")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        boxArea(height: 160)
                    }
                    
                    // Notes Dot Grid Area
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Usage Notes / บันทึกการใช้งานและข้อยกเว้น")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        ZStack(alignment: .topLeading) {
                            boxArea(height: h - 450)
                            DotGridPaperView(spacing: 16, dotColor: AppTheme.sageGreen.opacity(0.12))
                                .padding(8)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)
            }
        }
    }
    
    private func boxArea(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(AppTheme.sageGreen.opacity(0.15), lineWidth: 0.8)
            .background(Color.white)
            .frame(height: height)
    }
}

// MARK: - 5. Sentence Practice Sheet
struct SentencePracticeTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let rowH: CGFloat = 72
            let topPadding: CGFloat = 54
            
            let col1 = w * 0.44
            let col2 = w * 0.64
            let col3 = w * 0.84
            
            ZStack(alignment: .topLeading) {
                // Header
                HStack {
                    Text("SENTENCE PRACTICE  /  ตารางแปลและฝึกแต่งประโยค")
                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                // Column headers
                HStack(spacing: 0) {
                    Text("Japanese Sentence / แต่งประโยคภาษาญี่ปุ่น").frame(width: col1, alignment: .center)
                    Text("Reading / คำอ่าน").frame(width: col2 - col1, alignment: .center)
                    Text("Thai Translation / คำแปลไทย").frame(width: col3 - col2, alignment: .center)
                    Text("Notes / บันทึก").frame(width: w - col3 - 20, alignment: .center)
                }
                .font(AppTheme.fontRounded(size: 8, weight: .bold))
                .foregroundColor(AppTheme.textMuted.opacity(0.7))
                .padding(.top, topPadding - 12)
                
                Path { path in
                    // Vertical dividers
                    path.move(to: CGPoint(x: col1, y: topPadding))
                    path.addLine(to: CGPoint(x: col1, y: h - 20))
                    
                    path.move(to: CGPoint(x: col2, y: topPadding))
                    path.addLine(to: CGPoint(x: col2, y: h - 20))
                    
                    path.move(to: CGPoint(x: col3, y: topPadding))
                    path.addLine(to: CGPoint(x: col3, y: h - 20))
                    
                    // Horizontal rows
                    var y = topPadding
                    while y < h - 20 {
                        path.move(to: CGPoint(x: 16, y: y))
                        path.addLine(to: CGPoint(x: w - 16, y: y))
                        y += rowH
                    }
                    path.move(to: CGPoint(x: 16, y: h - 20))
                    path.addLine(to: CGPoint(x: w - 16, y: h - 20))
                }
                .stroke(AppTheme.sageGreen.opacity(0.18), lineWidth: 0.8)
            }
        }
    }
}

// MARK: - 6. Lesson Summary Sheet
struct LessonSummaryTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let colW = (w - 60) / 2
            
            ZStack(alignment: .topLeading) {
                // Header
                HStack {
                    Text("LESSON SUMMARY SHEET  /  สรุปบทเรียนและคำถาม")
                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                VStack(spacing: 16) {
                    // Date & Topic Box
                    HStack(spacing: 16) {
                        Text("Date: ....................")
                        Text("Topic / Lesson: ..............................................................")
                    }
                    .font(AppTheme.fontRounded(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.sageGreen.opacity(0.18), lineWidth: 0.8))
                    
                    // Grid cards
                    HStack(alignment: .top, spacing: 16) {
                        // Left column
                        VStack(spacing: 16) {
                            cardBox(title: "New Words & Expressions / คำศัพท์และสำนวนใหม่", height: 260)
                            cardBox(title: "Grammar Summary / โครงสร้างไวยากรณ์เด่น", height: 280)
                        }
                        .frame(width: colW)
                        
                        // Right column
                        VStack(spacing: 16) {
                            cardBox(title: "Difficult Points & Questions / จุดที่ยังงงหรือคำถาม", height: 260)
                            cardBox(title: "Exercises & Homework / การบ้านและงานที่ได้รับมอบหมาย", height: 280)
                        }
                        .frame(width: colW)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 48)
            }
        }
    }
    
    private func cardBox(title: String, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.fontRounded(size: 8, weight: .bold))
                .foregroundColor(AppTheme.textMuted.opacity(0.6))
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.sageGreen.opacity(0.18), lineWidth: 0.8)
                    .frame(height: height)
                
                RuledPaperView(spacing: 22, lineColor: AppTheme.sageGreen.opacity(0.1))
                    .padding(6)
            }
        }
    }
}

// MARK: - 7. Cornell Notes
struct CornellNotesTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let topH: CGFloat = 80
            let bottomH: CGFloat = 160
            let cueW: CGFloat = w * 0.3
            
            ZStack(alignment: .topLeading) {
                // Background Structure Lines
                Path { path in
                    // Horizontal top block line
                    path.move(to: CGPoint(x: 16, y: topH))
                    path.addLine(to: CGPoint(x: w - 16, y: topH))
                    
                    // Vertical Cornell Cue line
                    path.move(to: CGPoint(x: cueW, y: topH))
                    path.addLine(to: CGPoint(x: cueW, y: h - bottomH))
                    
                    // Horizontal Cornell Summary line
                    path.move(to: CGPoint(x: 16, y: h - bottomH))
                    path.addLine(to: CGPoint(x: w - 16, y: h - bottomH))
                }
                .stroke(AppTheme.sageGreen.opacity(0.2), lineWidth: 1.2)
                
                // Ruled lines inside Note taking column
                RuledPaperView(spacing: 24, lineColor: AppTheme.sageGreen.opacity(0.08))
                    .frame(width: w - cueW - 20, height: h - topH - bottomH - 10)
                    .offset(x: cueW + 10, y: topH + 5)
                
                // Labels
                // Header section
                HStack(spacing: 24) {
                    Text("Subject / หัวข้อ: .......................................")
                    Text("Date: ....................")
                }
                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textMuted.opacity(0.6))
                .padding(.leading, 24)
                .padding(.top, 28)
                
                // Cue Cue Label
                Text("Cue / Keywords / ประเด็นหลัก")
                    .font(AppTheme.fontRounded(size: 8, weight: .bold))
                    .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    .offset(x: 24, y: topH + 12)
                
                // Notes Column Label
                Text("Note-Taking / จดโน้ตรายละเอียด")
                    .font(AppTheme.fontRounded(size: 8, weight: .bold))
                    .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    .offset(x: cueW + 14, y: topH + 12)
                
                // Summary Block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary / สรุปประเด็นบทเรียน")
                        .font(AppTheme.fontRounded(size: 8, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    
                    // Lines inside summary
                    VStack(spacing: 18) {
                        Rectangle().fill(AppTheme.sageGreen.opacity(0.1)).frame(height: 0.8)
                        Rectangle().fill(AppTheme.sageGreen.opacity(0.1)).frame(height: 0.8)
                        Rectangle().fill(AppTheme.sageGreen.opacity(0.1)).frame(height: 0.8)
                    }
                }
                .padding(.horizontal, 24)
                .frame(width: w)
                .offset(y: h - bottomH + 12)
            }
        }
    }
}

// MARK: - 8. Daily Japanese Planner
struct DailyJapanesePlannerTemplateView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let halfW = (w - 60) / 2
            
            ZStack(alignment: .topLeading) {
                // Header Title
                HStack {
                    Text("DAILY JAPANESE PLANNER  /  บันทึกและเป้าหมายรายวัน")
                        .font(AppTheme.fontSerif(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                VStack(spacing: 16) {
                    // Goal Box
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's Goal / เป้าหมายประจำวัน")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        boxArea(height: 38)
                    }
                    
                    // Word shelf vs Review list row
                    HStack(alignment: .top, spacing: 16) {
                        // Words learned list
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Words Learned / คำศัพท์วันนี้")
                                .font(AppTheme.fontRounded(size: 8, weight: .bold))
                                .foregroundColor(AppTheme.textMuted.opacity(0.6))
                            
                            ZStack(alignment: .top) {
                                boxArea(height: 220)
                                RuledPaperView(spacing: 22, lineColor: AppTheme.sageGreen.opacity(0.08))
                                    .padding(6)
                            }
                        }
                        .frame(width: halfW)
                        
                        // Checklists to review
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Review Task Checklist / หัวข้อเรียนทบทวน")
                                .font(AppTheme.fontRounded(size: 8, weight: .bold))
                                .foregroundColor(AppTheme.textMuted.opacity(0.6))
                            
                            ZStack {
                                boxArea(height: 220)
                                VStack(spacing: 16) {
                                    ForEach(0..<6, id: \.self) { _ in
                                        HStack(spacing: 8) {
                                            Circle()
                                                .stroke(AppTheme.sageGreen.opacity(0.3), lineWidth: 1)
                                                .frame(width: 10, height: 10)
                                            Rectangle()
                                                .fill(AppTheme.sageGreen.opacity(0.1))
                                                .frame(height: 0.8)
                                        }
                                    }
                                }
                                .padding(14)
                            }
                        }
                        .frame(width: halfW)
                    }
                    
                    // Practice memo grid
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Practice Grid & Memo / คัดคันจิและจดบันทึก")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        
                        ZStack(alignment: .topLeading) {
                            boxArea(height: h - 380)
                            GridPaperView(spacing: 20, lineColor: AppTheme.sageGreen.opacity(0.08))
                                .padding(8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 46)
            }
        }
    }
    
    private func boxArea(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(AppTheme.sageGreen.opacity(0.18), lineWidth: 0.8)
            .background(Color.white)
            .frame(height: height)
    }
}
