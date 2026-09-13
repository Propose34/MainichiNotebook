import Foundation

/// Paper style options per page. Stored in LecturePage so each page independently
/// remembers its paper type. Defaults to .grid for backward compatibility.
enum PaperPreset: String, Codable, CaseIterable, Identifiable {
    case blank        = "Blank"
    case ruled        = "Ruled"
    case grid         = "Grid"
    case dotGrid      = "Dot Grid"
    case genkouYoushi = "Genkou"
    case kana         = "Kana"
    case kanji        = "Kanji"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blank:        return "Blank"
        case .ruled:        return "Ruled"
        case .grid:         return "Grid"
        case .dotGrid:      return "Dots"
        case .genkouYoushi: return "原稿用紙"
        case .kana:         return "かな"
        case .kanji:        return "漢字"
        }
    }

    var icon: String {
        switch self {
        case .blank:        return "doc"
        case .ruled:        return "line.3.horizontal"
        case .grid:         return "grid"
        case .dotGrid:      return "square.grid.3x3"
        case .genkouYoushi: return "square.grid.4x3.fill"
        case .kana:         return "a.magnify"
        case .kanji:        return "character"
        }
    }
}
