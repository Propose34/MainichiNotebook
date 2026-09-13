import Foundation

struct AttachmentItem: Identifiable, Codable, Equatable {
    let id: UUID
    let fileName: String
    let localPath: String // Relative folder storage path
    
    init(id: UUID = UUID(), fileName: String, localPath: String) {
        self.id = id
        self.fileName = fileName
        self.localPath = localPath
    }
}
