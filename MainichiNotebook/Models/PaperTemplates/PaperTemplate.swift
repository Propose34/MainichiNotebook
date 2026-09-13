import Foundation

struct PaperTemplate: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var subtitle: String?
    var kind: PaperTemplateKind
    var source: PaperTemplateSource

    var builtInPresetId: String?     // e.g., "blank", "ruled", "vocabTable", etc.
    var localFileName: String?       // e.g., "<uuid>.pdf" or "<uuid>.png"
    var thumbnailFileName: String?   // e.g., "<uuid>_thumb.jpg"

    var pageCount: Int?
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
}
