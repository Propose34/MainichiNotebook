import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

struct AppTheme {
    // Colors
    static let paperBackground = Color(hex: "F9F6F0")
    static let paperBeige = Color(hex: "F3EFE6")
    static let paperCard = Color(hex: "FFFFFF")
    static let darkNavy = Color(hex: "131B26")
    static let darkNavyActive = Color(hex: "23334A")
    static let darkNavySidebarSelected = Color(hex: "213045")
    static let sakuraPink = Color(hex: "EAA09B")
    static let sakuraPinkLight = Color(hex: "FCEEEF")
    static let sageGreen = Color(hex: "8A9A86")
    static let sageGreenLight = Color(hex: "EEF2EF")
    static let woodCozy = Color(hex: "9E7B5C")
    static let woodDark = Color(hex: "805D41")
    static let textDark = Color(hex: "2C2C2C")
    static let textMuted = Color(hex: "6B6B6B")
    static let borderLight = Color(hex: "E8E5DF")
    
    // Dark Mode Colors
    static let darkBackground = Color(hex: "0F1520")
    static let darkCard = Color(hex: "1A2332")
    static let darkCardActive = Color(hex: "23334A")
    static let darkTextPrimary = Color.white
    static let darkTextSecondary = Color.white.opacity(0.6)
    static let darkBorder = Color.white.opacity(0.12)
    
    // Spacing Scale
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24
    
    // Corner Radius Scale
    static let cornerSM: CGFloat = 8
    static let cornerMD: CGFloat = 12
    static let cornerLG: CGFloat = 16
    static let cornerXL: CGFloat = 20
    
    // Shadows
    static let cardShadow: CGFloat = 6
    static let shadowColor = Color.black.opacity(0.04)
    
    // Fonts (Standard System Styles to ensure compiling clean)
    static func fontSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .serif)
    }
    
    static func fontRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    // Typography Presets
    static let titleLarge = fontSerif(size: 26, weight: .bold)
    static let titleMedium = fontSerif(size: 20, weight: .bold)
    static let titleSmall = fontSerif(size: 16, weight: .bold)
    static let bodyLarge = fontRounded(size: 15, weight: .medium)
    static let bodyMedium = fontRounded(size: 13, weight: .regular)
    static let bodySmall = fontRounded(size: 11, weight: .regular)
    static let caption = fontRounded(size: 10, weight: .medium)
    static let labelBold = fontRounded(size: 12, weight: .bold)
}

// Background Grid view for paper effect
struct GridPaperView: View {
    var spacing: CGFloat = 22
    var lineColor: Color = Color(hex: "8A9A86").opacity(0.08) // Sage grid pattern
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                var x: CGFloat = 0
                while x < width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += spacing
                }
                
                // Horizontal lines
                var y: CGFloat = 0
                while y < height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += spacing
                }
            }
            .stroke(lineColor, lineWidth: 0.8)
        }
    }
}

// MARK: - Ruled Paper

struct RuledPaperView: View {
    var spacing: CGFloat = 26
    var lineColor: Color = Color(hex: "A3805D").opacity(0.12)

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                var y: CGFloat = spacing
                while y < height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += spacing
                }
            }
            .stroke(lineColor, lineWidth: 0.8)
        }
    }
}

// MARK: - Dot Grid Paper

struct DotGridPaperView: View {
    var spacing: CGFloat = 22
    var dotColor: Color = Color(hex: "8A9A86").opacity(0.25)

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var x: CGFloat = spacing
                while x < size.width {
                    var y: CGFloat = spacing
                    while y < size.height {
                        let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                        context.fill(Path(ellipseIn: rect), with: .color(UIColor(dotColor).withAlphaComponent(0.4).toSwiftUIColor()))
                        y += spacing
                    }
                    x += spacing
                }
            }
        }
    }
}

// MARK: - Genkou Youshi (原稿用紙) — Japanese manuscript paper

struct GenkouYoushiView: View {
    var columns: Int = 20
    var rows: Int = 10
    var lineColor: Color = Color(hex: "8A9A86").opacity(0.25)

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(columns)
            let cellH = geo.size.height / CGFloat(rows)

            Path { path in
                // Vertical lines
                for col in 0...columns {
                    let x = CGFloat(col) * cellW
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                // Horizontal lines
                for row in 0...rows {
                    let y = CGFloat(row) * cellH
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                // Inner cross-hair guides (center marks on each cell)
                for col in 0..<columns {
                    for row in 0..<rows {
                        let cx = CGFloat(col) * cellW + cellW / 2
                        let cy = CGFloat(row) * cellH + cellH / 2
                        // Small cross at center
                        path.move(to: CGPoint(x: cx - 3, y: cy))
                        path.addLine(to: CGPoint(x: cx + 3, y: cy))
                        path.move(to: CGPoint(x: cx, y: cy - 3))
                        path.addLine(to: CGPoint(x: cx, y: cy + 3))
                    }
                }
            }
            .stroke(lineColor, lineWidth: 0.7)
        }
    }
}

// MARK: - Kana Practice Grid — small boxes with baseline

struct KanaPracticeView: View {
    var columns: Int = 10
    var rows: Int = 8
    var lineColor: Color = Color(hex: "EAA09B").opacity(0.3)

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(columns)
            let cellH = geo.size.height / CGFloat(rows)

            Path { path in
                for col in 0...columns {
                    let x = CGFloat(col) * cellW
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for row in 0...rows {
                    let y = CGFloat(row) * cellH
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                // Diagonal guides inside each cell for stroke direction
                for col in 0..<columns {
                    for row in 0..<rows {
                        let x0 = CGFloat(col) * cellW
                        let y0 = CGFloat(row) * cellH
                        path.move(to: CGPoint(x: x0, y: y0))
                        path.addLine(to: CGPoint(x: x0 + cellW, y: y0 + cellH))
                    }
                }
            }
            .stroke(lineColor, lineWidth: 0.5)
        }
    }
}

// MARK: - Kanji Practice Grid — larger boxes with 4-quadrant guides

struct KanjiPracticeView: View {
    var columns: Int = 6
    var rows: Int = 5
    var outerColor: Color = Color(hex: "3D5A80").opacity(0.3)
    var innerColor: Color = Color(hex: "3D5A80").opacity(0.12)

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(columns)
            let cellH = geo.size.height / CGFloat(rows)

            ZStack {
                // Outer grid (solid)
                Path { path in
                    for col in 0...columns {
                        let x = CGFloat(col) * cellW
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for row in 0...rows {
                        let y = CGFloat(row) * cellH
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(outerColor, lineWidth: 0.8)

                // Inner cross-hair guides (dashed)
                Path { path in
                    for col in 0..<columns {
                        for row in 0..<rows {
                            let x0 = CGFloat(col) * cellW
                            let y0 = CGFloat(row) * cellH
                            let cx = x0 + cellW / 2
                            let cy = y0 + cellH / 2
                            path.move(to: CGPoint(x: cx, y: y0))
                            path.addLine(to: CGPoint(x: cx, y: y0 + cellH))
                            path.move(to: CGPoint(x: x0, y: cy))
                            path.addLine(to: CGPoint(x: x0 + cellW, y: cy))
                        }
                    }
                }
                .stroke(innerColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
            }
        }
    }
}

// MARK: - UIColor helper for DotGridPaperView

private extension UIColor {
    func toSwiftUIColor() -> Color { Color(self) }
}
