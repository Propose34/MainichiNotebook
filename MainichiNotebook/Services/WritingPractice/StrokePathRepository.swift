import Foundation
import CoreGraphics

struct VisualStroke: Identifiable, Hashable {
    let id = UUID()
    let points: [CGPoint]
}

struct StrokePathRepository {
    static func paths(for character: String) -> [VisualStroke]? {
        switch character {
        // ==========================================
        // HIRAGANA
        // ==========================================
        // --- A Row ---
        case "あ":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 35), CGPoint(x: 75, y: 35)]),
                VisualStroke(points: [CGPoint(x: 50, y: 20), CGPoint(x: 46, y: 80)]),
                VisualStroke(points: [CGPoint(x: 45, y: 52), CGPoint(x: 32, y: 70), CGPoint(x: 38, y: 55), CGPoint(x: 68, y: 55), CGPoint(x: 65, y: 78), CGPoint(x: 48, y: 76)])
            ]
        case "い":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 30), CGPoint(x: 30, y: 70), CGPoint(x: 36, y: 70)]),
                VisualStroke(points: [CGPoint(x: 68, y: 40), CGPoint(x: 72, y: 60)])
            ]
        case "う":
            return [
                VisualStroke(points: [CGPoint(x: 45, y: 20), CGPoint(x: 60, y: 28)]),
                VisualStroke(points: [CGPoint(x: 32, y: 42), CGPoint(x: 68, y: 52), CGPoint(x: 52, y: 78), CGPoint(x: 38, y: 76)])
            ]
        case "え":
            return [
                VisualStroke(points: [CGPoint(x: 45, y: 20), CGPoint(x: 55, y: 28)]),
                VisualStroke(points: [CGPoint(x: 32, y: 45), CGPoint(x: 68, y: 45), CGPoint(x: 35, y: 75), CGPoint(x: 58, y: 62), CGPoint(x: 72, y: 75)])
            ]
        case "お":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 35), CGPoint(x: 65, y: 35)]),
                VisualStroke(points: [CGPoint(x: 46, y: 18), CGPoint(x: 46, y: 70), CGPoint(x: 36, y: 65), CGPoint(x: 48, y: 55), CGPoint(x: 68, y: 60), CGPoint(x: 62, y: 76)]),
                VisualStroke(points: [CGPoint(x: 68, y: 22), CGPoint(x: 76, y: 32)])
            ]
            
        // --- Ka Row ---
        case "か":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 45), CGPoint(x: 68, y: 35), CGPoint(x: 58, y: 76)]),
                VisualStroke(points: [CGPoint(x: 42, y: 24), CGPoint(x: 34, y: 65)]),
                VisualStroke(points: [CGPoint(x: 68, y: 24), CGPoint(x: 76, y: 34)])
            ]
        case "き":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 32), CGPoint(x: 68, y: 32)]),
                VisualStroke(points: [CGPoint(x: 30, y: 46), CGPoint(x: 70, y: 46)]),
                VisualStroke(points: [CGPoint(x: 52, y: 20), CGPoint(x: 52, y: 68), CGPoint(x: 58, y: 68)]),
                VisualStroke(points: [CGPoint(x: 38, y: 76), CGPoint(x: 62, y: 76)])
            ]
        case "く":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 38), CGPoint(x: 65, y: 50), CGPoint(x: 35, y: 62)])
            ]
        case "け":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 22), CGPoint(x: 30, y: 78), CGPoint(x: 36, y: 76)]),
                VisualStroke(points: [CGPoint(x: 42, y: 35), CGPoint(x: 74, y: 35)]),
                VisualStroke(points: [CGPoint(x: 58, y: 20), CGPoint(x: 58, y: 76)])
            ]
        case "こ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 35), CGPoint(x: 68, y: 35), CGPoint(x: 62, y: 42)]),
                VisualStroke(points: [CGPoint(x: 32, y: 68), CGPoint(x: 68, y: 68)])
            ]
            
        // --- Sa Row ---
        case "さ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 32), CGPoint(x: 70, y: 32)]),
                VisualStroke(points: [CGPoint(x: 52, y: 20), CGPoint(x: 52, y: 68), CGPoint(x: 58, y: 66)]),
                VisualStroke(points: [CGPoint(x: 38, y: 74), CGPoint(x: 62, y: 74)])
            ]
        case "し":
            return [
                VisualStroke(points: [CGPoint(x: 48, y: 22), CGPoint(x: 48, y: 72), CGPoint(x: 70, y: 78)])
            ]
        case "す":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 35), CGPoint(x: 75, y: 35)]),
                VisualStroke(points: [CGPoint(x: 50, y: 18), AppTheme.darkNavy == .clear ? CGPoint(x: 50, y: 55) : CGPoint(x: 50, y: 52), CGPoint(x: 42, y: 56), CGPoint(x: 42, y: 64), CGPoint(x: 50, y: 60), CGPoint(x: 50, y: 82)])
            ]
        case "せ":
            return [
                VisualStroke(points: [CGPoint(x: 24, y: 42), AppTheme.darkNavy == .clear ? CGPoint(x: 76, y: 42) : CGPoint(x: 74, y: 42)]),
                VisualStroke(points: [CGPoint(x: 62, y: 24), CGPoint(x: 62, y: 62)]),
                VisualStroke(points: [CGPoint(x: 38, y: 26), CGPoint(x: 38, y: 72), CGPoint(x: 68, y: 72)])
            ]
        case "そ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 28), CGPoint(x: 70, y: 28), CGPoint(x: 30, y: 62), CGPoint(x: 68, y: 62), CGPoint(x: 40, y: 78)])
            ]
            
        // --- Ta Row ---
        case "た":
            return [
                VisualStroke(points: [CGPoint(x: 24, y: 34), CGPoint(x: 54, y: 34)]),
                VisualStroke(points: [CGPoint(x: 38, y: 20), CGPoint(x: 34, y: 60)]),
                VisualStroke(points: [CGPoint(x: 60, y: 28), CGPoint(x: 76, y: 36)]),
                VisualStroke(points: [CGPoint(x: 58, y: 52), CGPoint(x: 78, y: 44)])
            ]
        case "ち":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 30), CGPoint(x: 75, y: 30)]),
                VisualStroke(points: [CGPoint(x: 50, y: 15), CGPoint(x: 50, y: 50), CGPoint(x: 30, y: 68), CGPoint(x: 55, y: 78), CGPoint(x: 72, y: 62)])
            ]
        case "つ":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 35), CGPoint(x: 70, y: 35), CGPoint(x: 70, y: 55), CGPoint(x: 30, y: 78)])
            ]
        case "て":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 30), CGPoint(x: 75, y: 30), CGPoint(x: 32, y: 74), CGPoint(x: 68, y: 78)])
            ]
        case "と":
            return [
                VisualStroke(points: [CGPoint(x: 52, y: 20), CGPoint(x: 68, y: 38)]),
                VisualStroke(points: [CGPoint(x: 35, y: 42), CGPoint(x: 72, y: 42), CGPoint(x: 72, y: 68), CGPoint(x: 45, y: 82)])
            ]
            
        // --- Na Row ---
        case "な":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 35), CGPoint(x: 50, y: 35)]),
                VisualStroke(points: [CGPoint(x: 38, y: 20), CGPoint(x: 32, y: 60)]),
                VisualStroke(points: [CGPoint(x: 65, y: 22), CGPoint(x: 74, y: 32)]),
                VisualStroke(points: [CGPoint(x: 55, y: 50), CGPoint(x: 55, y: 74), CGPoint(x: 42, y: 74), CGPoint(x: 52, y: 66)])
            ]
        case "に":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 20), CGPoint(x: 30, y: 80), CGPoint(x: 35, y: 78)]),
                VisualStroke(points: [CGPoint(x: 50, y: 38), CGPoint(x: 75, y: 38)]),
                VisualStroke(points: [CGPoint(x: 48, y: 62), CGPoint(x: 78, y: 62)])
            ]
        case "ぬ":
            return [
                VisualStroke(points: [CGPoint(x: 38, y: 25), CGPoint(x: 62, y: 75)]),
                VisualStroke(points: [CGPoint(x: 55, y: 20), CGPoint(x: 30, y: 55), CGPoint(x: 70, y: 55), CGPoint(x: 70, y: 75), CGPoint(x: 58, y: 75), CGPoint(x: 68, y: 68)])
            ]
        case "ね":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 20), CGPoint(x: 35, y: 80)]),
                VisualStroke(points: [CGPoint(x: 25, y: 32), CGPoint(x: 72, y: 32), CGPoint(x: 30, y: 75), CGPoint(x: 58, y: 55), CGPoint(x: 70, y: 68), CGPoint(x: 58, y: 78), CGPoint(x: 66, y: 74)])
            ]
        case "の":
            return [
                VisualStroke(points: [CGPoint(x: 52, y: 30), CGPoint(x: 38, y: 62), CGPoint(x: 68, y: 42), CGPoint(x: 72, y: 70), CGPoint(x: 46, y: 78)])
            ]
            
        // --- Ha Row ---
        case "は":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 20), CGPoint(x: 28, y: 78), CGPoint(x: 34, y: 76)]),
                VisualStroke(points: [CGPoint(x: 42, y: 35), CGPoint(x: 72, y: 35)]),
                VisualStroke(points: [CGPoint(x: 56, y: 20), CGPoint(x: 56, y: 70), CGPoint(x: 46, y: 68), CGPoint(x: 58, y: 60)])
            ]
        case "ひ":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 32), CGPoint(x: 45, y: 32), CGPoint(x: 28, y: 65), CGPoint(x: 72, y: 65), CGPoint(x: 55, y: 32), CGPoint(x: 75, y: 32)])
            ]
        case "ふ":
            return [
                VisualStroke(points: [CGPoint(x: 50, y: 20), CGPoint(x: 50, y: 32)]),
                VisualStroke(points: [CGPoint(x: 42, y: 45), CGPoint(x: 35, y: 62), CGPoint(x: 55, y: 75), CGPoint(x: 62, y: 68)]),
                VisualStroke(points: [CGPoint(x: 25, y: 52), CGPoint(x: 20, y: 62)]),
                VisualStroke(points: [CGPoint(x: 75, y: 52), CGPoint(x: 80, y: 62)])
            ]
        case "へ":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 60), CGPoint(x: 45, y: 35), CGPoint(x: 75, y: 62)])
            ]
        case "ほ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 20), CGPoint(x: 28, y: 78), CGPoint(x: 34, y: 76)]),
                VisualStroke(points: [CGPoint(x: 42, y: 30), CGPoint(x: 70, y: 30)]),
                VisualStroke(points: [CGPoint(x: 42, y: 48), CGPoint(x: 70, y: 48)]),
                VisualStroke(points: [CGPoint(x: 56, y: 20), CGPoint(x: 56, y: 70), CGPoint(x: 46, y: 68), CGPoint(x: 58, y: 60)])
            ]
            
        // --- Ma Row ---
        case "ま":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 30), CGPoint(x: 70, y: 30)]),
                VisualStroke(points: [CGPoint(x: 30, y: 48), CGPoint(x: 70, y: 48)]),
                VisualStroke(points: [CGPoint(x: 50, y: 18), CGPoint(x: 50, y: 70), CGPoint(x: 40, y: 68), CGPoint(x: 54, y: 60)])
            ]
        case "み":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 30), CGPoint(x: 65, y: 30), CGPoint(x: 38, y: 70), CGPoint(x: 30, y: 65), CGPoint(x: 48, y: 58), CGPoint(x: 75, y: 58)]),
                VisualStroke(points: [CGPoint(x: 60, y: 42), CGPoint(x: 50, y: 78)])
            ]
        case "む":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 38), CGPoint(x: 60, y: 38)]),
                VisualStroke(points: [CGPoint(x: 45, y: 20), CGPoint(x: 45, y: 65), CGPoint(x: 35, y: 65), CGPoint(x: 48, y: 55), CGPoint(x: 72, y: 62), CGPoint(x: 68, y: 72)]),
                VisualStroke(points: [CGPoint(x: 72, y: 28), CGPoint(x: 78, y: 38)])
            ]
        case "め":
            return [
                VisualStroke(points: [CGPoint(x: 42, y: 28), CGPoint(x: 58, y: 72)]),
                VisualStroke(points: [CGPoint(x: 32, y: 45), CGPoint(x: 68, y: 35), CGPoint(x: 72, y: 68), CGPoint(x: 46, y: 75)])
            ]
        case "も":
            return [
                VisualStroke(points: [CGPoint(x: 50, y: 20), CGPoint(x: 50, y: 70), CGPoint(x: 68, y: 72)]),
                VisualStroke(points: [CGPoint(x: 35, y: 38), CGPoint(x: 65, y: 38)]),
                VisualStroke(points: [CGPoint(x: 35, y: 52), CGPoint(x: 65, y: 52)])
            ]
            
        // --- Ya Row ---
        case "や":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 42), CGPoint(x: 65, y: 30), CGPoint(x: 60, y: 68), CGPoint(x: 42, y: 72)]),
                VisualStroke(points: [CGPoint(x: 42, y: 28), CGPoint(x: 48, y: 38)]),
                VisualStroke(points: [CGPoint(x: 68, y: 20), CGPoint(x: 58, y: 78)])
            ]
        case "ゆ":
            return [
                VisualStroke(points: [CGPoint(x: 45, y: 22), CGPoint(x: 45, y: 52), CGPoint(x: 30, y: 52), CGPoint(x: 68, y: 38), CGPoint(x: 62, y: 70), CGPoint(x: 48, y: 72)]),
                VisualStroke(points: [CGPoint(x: 60, y: 28), CGPoint(x: 50, y: 78)])
            ]
        case "よ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 38), CGPoint(x: 58, y: 38)]),
                VisualStroke(points: [CGPoint(x: 50, y: 20), CGPoint(x: 50, y: 68), CGPoint(x: 40, y: 65), CGPoint(x: 52, y: 58)])
            ]
            
        // --- Ra Row ---
        case "ら":
            return [
                VisualStroke(points: [CGPoint(x: 42, y: 22), CGPoint(x: 58, y: 28)]),
                VisualStroke(points: [CGPoint(x: 38, y: 48), CGPoint(x: 48, y: 48), CGPoint(x: 65, y: 60), CGPoint(x: 58, y: 80), CGPoint(x: 40, y: 78)])
            ]
        case "り":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 25), CGPoint(x: 32, y: 55), CGPoint(x: 38, y: 58)]),
                VisualStroke(points: [CGPoint(x: 65, y: 25), CGPoint(x: 68, y: 75), CGPoint(x: 58, y: 82)])
            ]
        case "る":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 25), CGPoint(x: 70, y: 25), CGPoint(x: 30, y: 60), CGPoint(x: 68, y: 60), CGPoint(x: 68, y: 76), CGPoint(x: 48, y: 76), AppTheme.darkNavy == .clear ? CGPoint(x: 48, y: 76) : CGPoint(x: 42, y: 68), CGPoint(x: 55, y: 68)])
            ]
        case "れ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 18), CGPoint(x: 32, y: 82)]),
                VisualStroke(points: [CGPoint(x: 32, y: 48), CGPoint(x: 55, y: 48), CGPoint(x: 40, y: 76), CGPoint(x: 55, y: 65), CGPoint(x: 72, y: 78)])
            ]
        case "ろ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 25), CGPoint(x: 70, y: 25), CGPoint(x: 30, y: 60), CGPoint(x: 65, y: 60), CGPoint(x: 70, y: 72), CGPoint(x: 40, y: 75)])
            ]
            
        // --- Wa Row ---
        case "わ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 18), CGPoint(x: 32, y: 82)]),
                VisualStroke(points: [CGPoint(x: 32, y: 48), CGPoint(x: 55, y: 48), CGPoint(x: 38, y: 76), CGPoint(x: 64, y: 50), CGPoint(x: 68, y: 75)])
            ]
        case "を":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 72, y: 32)]),
                VisualStroke(points: [CGPoint(x: 48, y: 18), CGPoint(x: 48, y: 55), CGPoint(x: 34, y: 55)]),
                VisualStroke(points: [CGPoint(x: 34, y: 55), CGPoint(x: 68, y: 55), CGPoint(x: 42, y: 78), CGPoint(x: 58, y: 78)])
            ]
        case "ん":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 28), CGPoint(x: 32, y: 74), CGPoint(x: 65, y: 38), CGPoint(x: 45, y: 78), CGPoint(x: 75, y: 78)])
            ]

        // ==========================================
        // KATAKANA
        // ==========================================
        // --- A Row ---
        case "ア":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 68, y: 32), CGPoint(x: 45, y: 55)]),
                VisualStroke(points: [CGPoint(x: 45, y: 55), CGPoint(x: 36, y: 78)])
            ]
        case "イ":
            return [
                VisualStroke(points: [CGPoint(x: 68, y: 25), CGPoint(x: 38, y: 52)]),
                VisualStroke(points: [CGPoint(x: 52, y: 40), CGPoint(x: 52, y: 80)])
            ]
        case "ウ":
            return [
                VisualStroke(points: [CGPoint(x: 50, y: 18), CGPoint(x: 50, y: 28)]),
                VisualStroke(points: [CGPoint(x: 32, y: 35), CGPoint(x: 32, y: 48)]),
                VisualStroke(points: [CGPoint(x: 32, y: 38), CGPoint(x: 70, y: 38), CGPoint(x: 48, y: 78)])
            ]
        case "エ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 28), CGPoint(x: 68, y: 28)]),
                VisualStroke(points: [CGPoint(x: 50, y: 28), CGPoint(x: 50, y: 72)]),
                VisualStroke(points: [CGPoint(x: 24, y: 72), CGPoint(x: 76, y: 72)])
            ]
        case "オ":
            return [
                VisualStroke(points: [CGPoint(x: 24, y: 42), CGPoint(x: 76, y: 42)]),
                VisualStroke(points: [CGPoint(x: 50, y: 20), CGPoint(x: 50, y: 72), CGPoint(x: 42, y: 72)]),
                VisualStroke(points: [CGPoint(x: 50, y: 45), CGPoint(x: 70, y: 72)])
            ]
            
        // --- Ka Row ---
        case "カ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 68, y: 32), CGPoint(x: 68, y: 55), CGPoint(x: 48, y: 78)]),
                VisualStroke(points: [CGPoint(x: 48, y: 20), CGPoint(x: 38, y: 70)])
            ]
        case "キ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 32), CGPoint(x: 68, y: 32)]),
                VisualStroke(points: [CGPoint(x: 30, y: 48), CGPoint(x: 70, y: 48)]),
                VisualStroke(points: [CGPoint(x: 52, y: 20), CGPoint(x: 44, y: 78)])
            ]
        case "ク":
            return [
                VisualStroke(points: [CGPoint(x: 52, y: 26), CGPoint(x: 32, y: 48)]),
                VisualStroke(points: [CGPoint(x: 32, y: 48), CGPoint(x: 72, y: 48), CGPoint(x: 44, y: 78)])
            ]
        case "ケ":
            return [
                VisualStroke(points: [CGPoint(x: 54, y: 24), CGPoint(x: 32, y: 48)]),
                VisualStroke(points: [CGPoint(x: 32, y: 46), CGPoint(x: 72, y: 46)]),
                VisualStroke(points: [CGPoint(x: 50, y: 46), CGPoint(x: 44, y: 80)])
            ]
        case "コ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 32), CGPoint(x: 68, y: 32), CGPoint(x: 68, y: 68)]),
                VisualStroke(points: [CGPoint(x: 32, y: 68), CGPoint(x: 68, y: 68)])
            ]
            
        // --- Sa Row ---
        case "サ":
            return [
                VisualStroke(points: [CGPoint(x: 24, y: 38), CGPoint(x: 76, y: 38)]),
                VisualStroke(points: [CGPoint(x: 38, y: 24), CGPoint(x: 38, y: 64)]),
                VisualStroke(points: [CGPoint(x: 62, y: 22), CGPoint(x: 58, y: 74)])
            ]
        case "シ":
            return [
                VisualStroke(points: [CGPoint(x: 36, y: 32), CGPoint(x: 44, y: 42)]),
                VisualStroke(points: [CGPoint(x: 32, y: 52), CGPoint(x: 40, y: 62)]),
                VisualStroke(points: [CGPoint(x: 32, y: 76), CGPoint(x: 72, y: 42)])
            ]
        case "ス":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 35), CGPoint(x: 72, y: 35), AppTheme.darkNavy == .clear ? CGPoint(x: 72, y: 35) : CGPoint(x: 48, y: 75)]),
                VisualStroke(points: [CGPoint(x: 52, y: 52), CGPoint(x: 70, y: 75)])
            ]
        case "セ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 32), CGPoint(x: 72, y: 32), CGPoint(x: 72, y: 52), CGPoint(x: 46, y: 74)]),
                VisualStroke(points: [CGPoint(x: 48, y: 20), CGPoint(x: 48, y: 72)])
            ]
        case "ソ":
            return [
                VisualStroke(points: [CGPoint(x: 36, y: 32), CGPoint(x: 52, y: 44)]),
                VisualStroke(points: [CGPoint(x: 68, y: 28), CGPoint(x: 42, y: 76)])
            ]
            
        // --- Ta Row ---
        case "タ":
            return [
                VisualStroke(points: [CGPoint(x: 48, y: 26), CGPoint(x: 28, y: 48)]),
                VisualStroke(points: [CGPoint(x: 28, y: 38), CGPoint(x: 72, y: 38), CGPoint(x: 46, y: 80)]),
                VisualStroke(points: [CGPoint(x: 34, y: 58), CGPoint(x: 62, y: 58)])
            ]
        case "チ":
            return [
                VisualStroke(points: [CGPoint(x: 68, y: 24), CGPoint(x: 32, y: 38)]),
                VisualStroke(points: [CGPoint(x: 25, y: 48), CGPoint(x: 75, y: 48)]),
                VisualStroke(points: [CGPoint(x: 50, y: 48), CGPoint(x: 50, y: 80)])
            ]
        case "ツ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 30), CGPoint(x: 38, y: 45)]),
                VisualStroke(points: [CGPoint(x: 52, y: 35), CGPoint(x: 58, y: 50)]),
                VisualStroke(points: [CGPoint(x: 72, y: 30), CGPoint(x: 45, y: 80)])
            ]
        case "テ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 32), CGPoint(x: 68, y: 32)]),
                VisualStroke(points: [CGPoint(x: 25, y: 50), CGPoint(x: 75, y: 50)]),
                VisualStroke(points: [CGPoint(x: 50, y: 50), CGPoint(x: 32, y: 80)])
            ]
        case "ト":
            return [
                VisualStroke(points: [CGPoint(x: 50, y: 20), CGPoint(x: 50, y: 78)]),
                VisualStroke(points: [CGPoint(x: 50, y: 48), CGPoint(x: 72, y: 72)])
            ]
            
        // --- Na Row ---
        case "ナ":
            return [
                VisualStroke(points: [CGPoint(x: 24, y: 38), CGPoint(x: 76, y: 38)]),
                VisualStroke(points: [CGPoint(x: 50, y: 22), CGPoint(x: 35, y: 78)])
            ]
        case "ニ":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 32), CGPoint(x: 65, y: 32)]),
                VisualStroke(points: [CGPoint(x: 25, y: 68), CGPoint(x: 75, y: 68)])
            ]
        case "ヌ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 72, y: 32), CGPoint(x: 38, y: 78)]),
                VisualStroke(points: [CGPoint(x: 45, y: 48), CGPoint(x: 68, y: 68)])
            ]
        case "ネ":
            return [
                VisualStroke(points: [CGPoint(x: 48, y: 20), CGPoint(x: 42, y: 32)]),
                VisualStroke(points: [CGPoint(x: 25, y: 42), CGPoint(x: 72, y: 42), CGPoint(x: 42, y: 80)]),
                VisualStroke(points: [CGPoint(x: 42, y: 50), CGPoint(x: 32, y: 75)]),
                VisualStroke(points: [CGPoint(x: 52, y: 50), CGPoint(x: 70, y: 72)])
            ]
        case "ノ":
            return [
                VisualStroke(points: [CGPoint(x: 68, y: 25), CGPoint(x: 32, y: 80)])
            ]
            
        // --- Ha Row ---
        case "ハ":
            return [
                VisualStroke(points: [CGPoint(x: 40, y: 32), CGPoint(x: 28, y: 72)]),
                VisualStroke(points: [CGPoint(x: 60, y: 32), CGPoint(x: 72, y: 72)])
            ]
        case "ヒ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 30), CGPoint(x: 68, y: 30)]),
                VisualStroke(points: [CGPoint(x: 30, y: 52), CGPoint(x: 68, y: 52), CGPoint(x: 68, y: 25)])
            ]
        case "フ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 72, y: 32), CGPoint(x: 40, y: 75)])
            ]
        case "ヘ":
            return [
                VisualStroke(points: [CGPoint(x: 25, y: 60), CGPoint(x: 48, y: 35), CGPoint(x: 75, y: 62)])
            ]
        case "ホ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 42), CGPoint(x: 72, y: 42)]),
                VisualStroke(points: [CGPoint(x: 50, y: 18), CGPoint(x: 50, y: 72)]),
                VisualStroke(points: [CGPoint(x: 38, y: 52), AppTheme.darkNavy == .clear ? CGPoint(x: 28, y: 72) : CGPoint(x: 28, y: 72)]),
                VisualStroke(points: [CGPoint(x: 62, y: 52), CGPoint(x: 72, y: 72)])
            ]
            
        // --- Ma Row ---
        case "マ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 72, y: 32), CGPoint(x: 45, y: 55)]),
                VisualStroke(points: [CGPoint(x: 32, y: 58), CGPoint(x: 68, y: 58)])
            ]
        case "ミ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 28), CGPoint(x: 58, y: 40)]),
                VisualStroke(points: [CGPoint(x: 25, y: 48), CGPoint(x: 53, y: 60)]),
                VisualStroke(points: [CGPoint(x: 20, y: 68), CGPoint(x: 48, y: 80)])
            ]
        case "ム":
            return [
                VisualStroke(points: [CGPoint(x: 45, y: 22), CGPoint(x: 25, y: 55), CGPoint(x: 72, y: 55)]),
                VisualStroke(points: [CGPoint(x: 58, y: 42), CGPoint(x: 70, y: 28)])
            ]
        case "メ":
            return [
                VisualStroke(points: [CGPoint(x: 68, y: 25), CGPoint(x: 32, y: 78)]),
                VisualStroke(points: [CGPoint(x: 35, y: 38), CGPoint(x: 68, y: 68)])
            ]
        case "モ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 32), CGPoint(x: 70, y: 32)]),
                VisualStroke(points: [CGPoint(x: 30, y: 52), CGPoint(x: 70, y: 52)]),
                VisualStroke(points: [CGPoint(x: 50, y: 20), CGPoint(x: 50, y: 72), CGPoint(x: 72, y: 72)])
            ]
            
        // --- Ya Row ---
        case "ヤ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 48), CGPoint(x: 68, y: 48), CGPoint(x: 50, y: 78)]),
                VisualStroke(points: [CGPoint(x: 58, y: 24), CGPoint(x: 42, y: 38)])
            ]
        case "ユ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 68, y: 32), CGPoint(x: 68, y: 65), CGPoint(x: 28, y: 65)]),
                VisualStroke(points: [CGPoint(x: 48, y: 32), CGPoint(x: 48, y: 80)])
            ]
        case "ヨ":
            return [
                VisualStroke(points: [CGPoint(x: 32, y: 30), CGPoint(x: 68, y: 30), CGPoint(x: 68, y: 70), CGPoint(x: 32, y: 70)]),
                VisualStroke(points: [CGPoint(x: 32, y: 50), CGPoint(x: 65, y: 50)]),
                VisualStroke(points: [CGPoint(x: 32, y: 30), CGPoint(x: 32, y: 70)])
            ]
            
        // --- Ra Row ---
        case "ラ":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 28), CGPoint(x: 65, y: 28)]),
                VisualStroke(points: [CGPoint(x: 30, y: 50), CGPoint(x: 70, y: 50), CGPoint(x: 45, y: 80)])
            ]
        case "リ":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 28), CGPoint(x: 32, y: 65)]),
                VisualStroke(points: [CGPoint(x: 65, y: 25), CGPoint(x: 65, y: 78)])
            ]
        case "ル":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 25), CGPoint(x: 32, y: 62), CGPoint(x: 38, y: 64)]),
                VisualStroke(points: [CGPoint(x: 58, y: 25), CGPoint(x: 62, y: 68), CGPoint(x: 72, y: 72)])
            ]
        case "レ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 25), CGPoint(x: 30, y: 75), CGPoint(x: 72, y: 45)])
            ]
        case "ロ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 28), CGPoint(x: 30, y: 72)]),
                VisualStroke(points: [CGPoint(x: 30, y: 28), CGPoint(x: 70, y: 28), CGPoint(x: 70, y: 72)]),
                VisualStroke(points: [CGPoint(x: 30, y: 72), CGPoint(x: 70, y: 72)])
            ]
            
        // --- Wa Row ---
        case "ワ":
            return [
                VisualStroke(points: [CGPoint(x: 28, y: 32), CGPoint(x: 68, y: 32), CGPoint(x: 45, y: 80)]),
                VisualStroke(points: [CGPoint(x: 48, y: 32), CGPoint(x: 32, y: 80)])
            ]
        case "ヲ":
            return [
                VisualStroke(points: [CGPoint(x: 30, y: 30), CGPoint(x: 70, y: 30)]),
                VisualStroke(points: [CGPoint(x: 30, y: 50), CGPoint(x: 70, y: 50)]),
                VisualStroke(points: [CGPoint(x: 46, y: 30), CGPoint(x: 46, y: 75), CGPoint(x: 32, y: 75)])
            ]
        case "ン":
            return [
                VisualStroke(points: [CGPoint(x: 35, y: 32), CGPoint(x: 45, y: 48)]),
                VisualStroke(points: [CGPoint(x: 32, y: 76), CGPoint(x: 72, y: 42)])
            ]
            
        default:
            return nil
        }
    }
}
