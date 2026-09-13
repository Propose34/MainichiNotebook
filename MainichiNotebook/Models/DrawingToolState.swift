import SwiftUI
import Foundation

// MARK: - EditorTool

enum EditorTool: String, CaseIterable, Identifiable, Codable {
    case pen        = "Pen"
    case pencil     = "Pencil"
    case highlighter = "Highlighter"
    case eraser     = "Eraser"
    case selectMove = "SelectMove"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pen:         return "pencil.tip"
        case .pencil:      return "pencil"
        case .highlighter: return "highlighter"
        case .eraser:      return "eraser.line.dashed"
        case .selectMove:  return "hand.point.up.left"
        }
    }

    var label: String {
        switch self {
        case .pen:         return "Pen"
        case .pencil:      return "Pencil"
        case .highlighter: return "Marker"
        case .eraser:      return "Eraser"
        case .selectMove:  return "Select"
        }
    }

    /// True for tools that produce ink strokes and need color/width settings.
    var isInkingTool: Bool {
        switch self {
        case .pen, .pencil, .highlighter: return true
        default: return false
        }
    }
}

// MARK: - PenType

enum PenType: String, CaseIterable, Identifiable, Codable {
    case ballpoint = "Ballpoint"
    case fountain  = "Fountain"
    case brush     = "Brush"
    case smoothStudy = "Smooth Study"

    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .ballpoint: return "Ballpoint"
        case .fountain:  return "Fountain"
        case .brush:     return "Brush"
        case .smoothStudy: return "Smooth Study"
        }
    }
}

// MARK: - PenPresetItem

struct PenPresetItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var penType: PenType
    var thickness: CGFloat
    var opacity: CGFloat
    var colorHex: String
}

// MARK: - FavoriteToolItem

struct FavoriteToolItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var tool: EditorTool
    var penType: PenType
    var thickness: CGFloat
    var opacity: CGFloat
    var colorHex: String
}

// MARK: - DrawingToolState

/// Single source of truth for all drawing-related editor state.
struct DrawingToolState {
    var tool: EditorTool        = .pen
    var colorHex: String        = "131B26"       // Current color
    var opacity: CGFloat        = 1.0            // Current opacity
    var activePenType: PenType  = .smoothStudy   // Current pen style

    // Editable presets for Pen tool (stores type, thickness, opacity, color)
    var penPresets: [PenPresetItem] = []
    var selectedPenPresetIndex: Int = 0 // Default standard preset

    // Dynamic widths for Pencil & Highlighter
    var pencilPresetWidths: [CGFloat]    = [1.0, 2.5, 6.0]
    var highlighterPresetWidths: [CGFloat] = [12.0, 24.0, 48.0]
    
    var selectedPencilPresetIndex: Int    = 1
    var selectedHighlighterPresetIndex: Int = 0

    // Tool favorites quick-access
    var favorites: [FavoriteToolItem] = []

    // MARK: - Persistence Keys
    private static let presetsKey = "com.mainichi.penPresets"
    private static let selectedPresetKey = "com.mainichi.selectedPenPresetIndex"
    private static let favoritesKey = "com.mainichi.toolFavorites"

    // MARK: - Custom Init
    init() {
        // Load presets if they exist in UserDefaults
        if let data = UserDefaults.standard.data(forKey: Self.presetsKey),
           let decoded = try? JSONDecoder().decode([PenPresetItem].self, from: data) {
            self.penPresets = decoded
        } else {
            // Default presets
            self.penPresets = [
                PenPresetItem(name: "Lecture Pen", penType: .smoothStudy, thickness: 1.5, opacity: 1.0, colorHex: "131B26"),
                PenPresetItem(name: "Grammar Note", penType: .fountain, thickness: 3.5, opacity: 1.0, colorHex: "3D5A80"),
                PenPresetItem(name: "Heading", penType: .brush, thickness: 8.0, opacity: 1.0, colorHex: "B56B5D")
            ]
        }
        
        self.selectedPenPresetIndex = UserDefaults.standard.integer(forKey: Self.selectedPresetKey)
        if self.selectedPenPresetIndex < 0 || self.selectedPenPresetIndex >= self.penPresets.count {
            self.selectedPenPresetIndex = 0
        }
        
        // Load favorites if they exist in UserDefaults
        if let data = UserDefaults.standard.data(forKey: Self.favoritesKey),
           let decoded = try? JSONDecoder().decode([FavoriteToolItem].self, from: data) {
            self.favorites = decoded
        } else {
            // Default favorites
            self.favorites = [
                FavoriteToolItem(name: "Black Lecture", tool: .pen, penType: .smoothStudy, thickness: 1.5, opacity: 1.0, colorHex: "131B26"),
                FavoriteToolItem(name: "Blue Note", tool: .pen, penType: .fountain, thickness: 3.5, opacity: 1.0, colorHex: "3D5A80"),
                FavoriteToolItem(name: "Yellow Marker", tool: .highlighter, penType: .ballpoint, thickness: 15.0, opacity: 0.6, colorHex: "FEEA9A"),
                FavoriteToolItem(name: "Pink Marker", tool: .highlighter, penType: .ballpoint, thickness: 15.0, opacity: 0.6, colorHex: "F8BBD0"),
                FavoriteToolItem(name: "Eraser", tool: .eraser, penType: .ballpoint, thickness: 0, opacity: 1.0, colorHex: "000000")
            ]
        }
        
        applyCurrentToolState()
    }

    // MARK: Derived booleans
    var isDrawingMode: Bool    { tool != .selectMove }
    var isSelectMoveMode: Bool { tool == .selectMove }
    var showsColorAndWidth: Bool { tool.isInkingTool }

    // MARK: Dynamic Stroke Width
    var strokeWidth: CGFloat {
        get {
            switch tool {
            case .pen:
                if penPresets.isEmpty { return 1.5 }
                return penPresets[clampedPenIndex].thickness
            case .pencil:
                return pencilPresetWidths[clampedPencilIndex]
            case .highlighter:
                return highlighterPresetWidths[clampedHighlighterIndex]
            case .eraser, .selectMove:
                return 0
            }
        }
        set {
            switch tool {
            case .pen:
                if !penPresets.isEmpty {
                    penPresets[clampedPenIndex].thickness = newValue
                    savePresets()
                }
            case .pencil:
                pencilPresetWidths[clampedPencilIndex] = newValue
            case .highlighter:
                highlighterPresetWidths[clampedHighlighterIndex] = newValue
            case .eraser, .selectMove:
                break
            }
        }
    }

    var clampedPenIndex: Int {
        if penPresets.isEmpty { return 0 }
        return max(0, min(selectedPenPresetIndex, penPresets.count - 1))
    }
    
    private var clampedPencilIndex: Int {
        max(0, min(selectedPencilPresetIndex, pencilPresetWidths.count - 1))
    }
    
    private var clampedHighlighterIndex: Int {
        max(0, min(selectedHighlighterPresetIndex, highlighterPresetWidths.count - 1))
    }

    // Min and Max thickness bounds per tool
    var minThickness: CGFloat {
        switch tool {
        case .highlighter:
            return 5.0
        case .pen:
            if penPresets.isEmpty { return 0.5 }
            let type = penPresets[clampedPenIndex].penType
            return type == .brush ? 2.0 : 0.5
        default:
            return 0.5
        }
    }

    var maxThickness: CGFloat {
        switch tool {
        case .highlighter:
            return 80.0
        case .pen:
            if penPresets.isEmpty { return 15.0 }
            let type = penPresets[clampedPenIndex].penType
            return type == .brush ? 40.0 : 15.0
        default:
            return 15.0
        }
    }

    // MARK: Mutating helpers

    mutating func selectTool(_ newTool: EditorTool) {
        tool = newTool
        applyCurrentToolState()
    }

    mutating func selectColor(_ hex: String) {
        colorHex = hex
        if tool == .pen && !penPresets.isEmpty {
            penPresets[clampedPenIndex].colorHex = hex
            savePresets()
        }
    }

    mutating func setOpacity(_ val: CGFloat) {
        opacity = val
        if tool == .pen && !penPresets.isEmpty {
            penPresets[clampedPenIndex].opacity = val
            savePresets()
        }
    }

    mutating func setPenType(_ type: PenType) {
        activePenType = type
        if tool == .pen && !penPresets.isEmpty {
            penPresets[clampedPenIndex].penType = type
            savePresets()
        }
    }

    mutating func selectPenPreset(index: Int) {
        selectedPenPresetIndex = index
        applyCurrentToolState()
        savePresets()
    }

    /// Syncs current tool settings from the selected preset.
    private mutating func applyCurrentToolState() {
        if tool == .pen && !penPresets.isEmpty {
            let preset = penPresets[clampedPenIndex]
            colorHex = preset.colorHex
            opacity = preset.opacity
            activePenType = preset.penType
        }
    }

    // MARK: - Save Helpers
    func savePresets() {
        if let data = try? JSONEncoder().encode(penPresets) {
            UserDefaults.standard.set(data, forKey: Self.presetsKey)
        }
        UserDefaults.standard.set(selectedPenPresetIndex, forKey: Self.selectedPresetKey)
    }

    func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: Self.favoritesKey)
        }
    }

    // MARK: - Preset & Favorite Mutators
    mutating func saveCurrentToPreset() {
        let activeIdx = clampedPenIndex
        guard activeIdx >= 0 && activeIdx < penPresets.count else { return }
        var preset = penPresets[activeIdx]
        preset.penType = activePenType
        preset.thickness = strokeWidth
        preset.opacity = opacity
        preset.colorHex = colorHex
        penPresets[activeIdx] = preset
        savePresets()
    }

    mutating func resetPresetToDefault(index: Int) {
        guard index >= 0 && index < penPresets.count else { return }
        let defaults = [
            PenPresetItem(name: "Lecture Pen", penType: .smoothStudy, thickness: 1.5, opacity: 1.0, colorHex: "131B26"),
            PenPresetItem(name: "Grammar Note", penType: .fountain, thickness: 3.5, opacity: 1.0, colorHex: "3D5A80"),
            PenPresetItem(name: "Heading", penType: .brush, thickness: 8.0, opacity: 1.0, colorHex: "B56B5D")
        ]
        if index < defaults.count {
            penPresets[index] = defaults[index]
            if index == selectedPenPresetIndex {
                applyCurrentToolState()
            }
            savePresets()
        }
    }

    mutating func addCurrentAsFavorite(name: String) {
        let nameToUse = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Favorite" : name
        let thicknessToUse: CGFloat = strokeWidth
        
        let newItem = FavoriteToolItem(
            name: nameToUse,
            tool: tool,
            penType: tool == .pen ? activePenType : .ballpoint,
            thickness: thicknessToUse,
            opacity: opacity,
            colorHex: colorHex
        )
        favorites.append(newItem)
        saveFavorites()
    }

    mutating func deleteFavorite(id: UUID) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }

    mutating func renameFavorite(id: UUID, newName: String) {
        if let idx = favorites.firstIndex(where: { $0.id == id }) {
            favorites[idx].name = newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Favorite" : newName
            saveFavorites()
        }
    }

    mutating func applyFavorite(_ item: FavoriteToolItem) {
        tool = item.tool
        if item.tool == .pen {
            if !penPresets.isEmpty {
                penPresets[clampedPenIndex].penType = item.penType
                penPresets[clampedPenIndex].thickness = item.thickness
                penPresets[clampedPenIndex].opacity = item.opacity
                penPresets[clampedPenIndex].colorHex = item.colorHex
            }
            activePenType = item.penType
            colorHex = item.colorHex
            opacity = item.opacity
            savePresets()
        } else if item.tool == .pencil {
            colorHex = item.colorHex
            opacity = item.opacity
            if let firstIndex = pencilPresetWidths.firstIndex(of: item.thickness) {
                selectedPencilPresetIndex = firstIndex
            } else if pencilPresetWidths.indices.contains(selectedPencilPresetIndex) {
                pencilPresetWidths[selectedPencilPresetIndex] = item.thickness
            } else {
                pencilPresetWidths.append(item.thickness)
                selectedPencilPresetIndex = pencilPresetWidths.count - 1
            }
        } else if item.tool == .highlighter {
            colorHex = item.colorHex
            opacity = item.opacity
            if let firstIndex = highlighterPresetWidths.firstIndex(of: item.thickness) {
                selectedHighlighterPresetIndex = firstIndex
            } else if highlighterPresetWidths.indices.contains(selectedHighlighterPresetIndex) {
                highlighterPresetWidths[selectedHighlighterPresetIndex] = item.thickness
            } else {
                highlighterPresetWidths.append(item.thickness)
                selectedHighlighterPresetIndex = highlighterPresetWidths.count - 1
            }
        }
    }
}
