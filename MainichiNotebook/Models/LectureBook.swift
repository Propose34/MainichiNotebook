import Foundation

struct LectureBook: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var subtitle: String
    var coverColorHex: String
    var progress: Double // 0.0 to 1.0
    var subject: String
    var isFavorite: Bool
    var isCompleted: Bool
    var decorationEmoji: String // Small visual detail for the cover (e.g. cherry blossom 🌸)
    
    // PDF Fields
    var isPDF: Bool
    var pdfFileName: String? // Saved relative to book folder inside App Documents
    
    init(id: UUID = UUID(), title: String, subtitle: String, coverColorHex: String, progress: Double, subject: String, isFavorite: Bool, isCompleted: Bool, decorationEmoji: String, isPDF: Bool = false, pdfFileName: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coverColorHex = coverColorHex
        self.progress = progress
        self.subject = subject
        self.isFavorite = isFavorite
        self.isCompleted = isCompleted
        self.decorationEmoji = decorationEmoji
        self.isPDF = isPDF
        self.pdfFileName = pdfFileName
    }
}
