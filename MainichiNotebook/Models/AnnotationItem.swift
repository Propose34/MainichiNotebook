import Foundation

// MARK: - Annotation Type

enum AnnotationType: String, Codable {
    case image    // Inserted photo; content = image filename
    case sticker  // Emoji sticker; content = emoji string
    case postIt   // Typed sticky note; content = note text
    case text     // Plain movable text label; content = label text
}

// MARK: - Annotation Item

struct AnnotationItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: AnnotationType
    var content: String  // Text for postIt/text; filename for image; emoji for sticker
    var xOffset: Double  // Absolute X position on the 720×960 canvas
    var yOffset: Double  // Absolute Y position on the 720×960 canvas
    var width: Double
    var height: Double

    init(
        id: UUID = UUID(),
        type: AnnotationType,
        content: String,
        xOffset: Double = 100.0,
        yOffset: Double = 100.0,
        width: Double = 150.0,
        height: Double = 150.0
    ) {
        self.id      = id
        self.type    = type
        self.content = content
        self.xOffset = xOffset
        self.yOffset = yOffset
        self.width   = width
        self.height  = height
    }
}
