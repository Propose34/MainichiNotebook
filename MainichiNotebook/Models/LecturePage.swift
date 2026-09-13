import Foundation

struct LecturePage: Identifiable, Codable, Equatable {
    let id: UUID
    var pageNumber: Int
    var pdfPageNumber: Int?            // Index inside PDF (0-indexed), nil for blank pages
    var annotations: [AnnotationItem]
    var attachments: [AttachmentItem]
    var paperPreset: PaperPreset       // Per-page paper background; defaults to .grid
    
    // Phase 4G.2: Template fields
    var paperTemplateId: String?
    var customTemplateFileName: String?
    var customTemplateKind: String?

    init(
        id: UUID = UUID(),
        pageNumber: Int,
        pdfPageNumber: Int? = nil,
        annotations: [AnnotationItem] = [],
        attachments: [AttachmentItem] = [],
        paperPreset: PaperPreset = .grid,
        paperTemplateId: String? = nil,
        customTemplateFileName: String? = nil,
        customTemplateKind: String? = nil
    ) {
        self.id           = id
        self.pageNumber   = pageNumber
        self.pdfPageNumber = pdfPageNumber
        self.annotations  = annotations
        self.attachments  = attachments
        self.paperPreset  = paperPreset
        self.paperTemplateId = paperTemplateId
        self.customTemplateFileName = customTemplateFileName
        self.customTemplateKind = customTemplateKind
    }
}
