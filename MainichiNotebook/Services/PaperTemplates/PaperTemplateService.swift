import Foundation
import Combine
import UIKit
import PDFKit

@MainActor
final class PaperTemplateService: ObservableObject {
    @Published var templates: [PaperTemplate] = []
    
    private let fileManager = FileManager.default
    
    private var baseDirURL: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let docDir = paths[0]
        let dir = docDir.appendingPathComponent("MainichiUserData/PaperTemplates", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private var filesDirURL: URL {
        let url = baseDirURL.appendingPathComponent("files", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private var thumbnailsDirURL: URL {
        let url = baseDirURL.appendingPathComponent("thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private var metadataFileURL: URL {
        baseDirURL.appendingPathComponent("paper-templates.json")
    }
    
    init() {
        createDirectoriesIfNeeded()
        loadTemplates()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: filesDirURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailsDirURL, withIntermediateDirectories: true)
    }
    
    func loadTemplates() {
        let defaultBuiltIns = Self.builtInTemplates
        
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            // Write defaults
            self.templates = defaultBuiltIns
            saveTemplatesMetadata()
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataFileURL)
            let decoded = try JSONDecoder().decode([PaperTemplate].self, from: data)
            
            // Merge built-ins to ensure updates to built-ins are always present and not deleted
            var merged = defaultBuiltIns
            for imported in decoded where imported.kind != .builtIn {
                merged.append(imported)
            }
            // Keep favorites of built-ins if saved in JSON
            for saved in decoded where saved.kind == .builtIn && saved.isFavorite {
                if let idx = merged.firstIndex(where: { $0.id == saved.id }) {
                    merged[idx].isFavorite = true
                }
            }
            self.templates = merged
            saveTemplatesMetadata()
        } catch {
            print("[PaperTemplateService] Error loading templates metadata, resetting to default built-ins: \(error)")
            self.templates = defaultBuiltIns
        }
    }
    
    func saveTemplatesMetadata() {
        do {
            let data = try JSONEncoder().encode(templates)
            try data.write(to: metadataFileURL, options: .atomic)
        } catch {
            print("[PaperTemplateService] Error saving templates metadata: \(error)")
        }
    }
    
    func getTemplateFileURL(fileName: String) -> URL {
        filesDirURL.appendingPathComponent(fileName)
    }
    
    func getTemplateThumbnailURL(fileName: String) -> URL {
        thumbnailsDirURL.appendingPathComponent(fileName)
    }
    
    // MARK: - Actions
    
    func toggleFavorite(id: String) {
        if let idx = templates.firstIndex(where: { $0.id == id }) {
            templates[idx].isFavorite.toggle()
            templates[idx].updatedAt = Date()
            saveTemplatesMetadata()
        }
    }
    
    func renameTemplate(id: String, newName: String) {
        if let idx = templates.firstIndex(where: { $0.id == id && $0.kind != .builtIn }) {
            templates[idx].name = newName
            templates[idx].updatedAt = Date()
            saveTemplatesMetadata()
        }
    }
    
    func deleteTemplate(id: String) {
        guard let idx = templates.firstIndex(where: { $0.id == id && $0.kind != .builtIn }) else { return }
        let template = templates[idx]
        
        // Remove files
        if let file = template.localFileName {
            let fileURL = filesDirURL.appendingPathComponent(file)
            try? fileManager.removeItem(at: fileURL)
        }
        if let thumb = template.thumbnailFileName {
            let thumbURL = thumbnailsDirURL.appendingPathComponent(thumb)
            try? fileManager.removeItem(at: thumbURL)
        }
        
        templates.remove(at: idx)
        saveTemplatesMetadata()
    }
    
    func importTemplate(from fileURL: URL, name: String) async -> PaperTemplate? {
        let shouldAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileExtension = fileURL.pathExtension.lowercased()
        let kind: PaperTemplateKind
        if fileExtension == "pdf" {
            kind = .importedPDF
        } else if ["png", "jpg", "jpeg"].contains(fileExtension) {
            kind = .importedImage
        } else {
            return nil
        }
        
        let id = UUID().uuidString
        let destFileName = "\(id).\(fileExtension)"
        let destURL = filesDirURL.appendingPathComponent(destFileName)
        
        do {
            if fileManager.fileExists(atPath: destURL.path) {
                try? fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: fileURL, to: destURL)
        } catch {
            print("[PaperTemplateService] Error copying template file: \(error)")
            return nil
        }
        
        // Generate Thumbnail
        let thumbFileName = "\(id)_thumb.jpg"
        let thumbURL = thumbnailsDirURL.appendingPathComponent(thumbFileName)
        let canvasSize = CGSize(width: 120, height: 160)
        
        var successThumb = false
        if kind == .importedPDF {
            if let image = drawPDFPageFirst(url: destURL, to: canvasSize) {
                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                    try? jpegData.write(to: thumbURL)
                    successThumb = true
                }
            }
        } else {
            if let image = drawImage(url: destURL, to: canvasSize) {
                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                    try? jpegData.write(to: thumbURL)
                    successThumb = true
                }
            }
        }
        
        let newTemplate = PaperTemplate(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Imported Template" : name,
            subtitle: kind == .importedPDF ? "Imported PDF Template" : "Imported Image Template",
            kind: kind,
            source: .localFile,
            builtInPresetId: nil,
            localFileName: destFileName,
            thumbnailFileName: successThumb ? thumbFileName : nil,
            pageCount: 1,
            isFavorite: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        templates.append(newTemplate)
        saveTemplatesMetadata()
        return newTemplate
    }
    
    // MARK: - Helpers
    
    private func drawPDFPageFirst(url: URL, to size: CGSize) -> UIImage? {
        guard let doc = PDFDocument(url: url),
              let page = doc.page(at: 0) else { return nil }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            let cgContext = ctx.cgContext
            cgContext.saveGState()
            
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)
            
            let scaleX = size.width / pageRect.width
            let scaleY = size.height / pageRect.height
            let scale = min(scaleX, scaleY)
            
            let tx = (size.width - pageRect.width * scale) / 2
            let ty = (size.height - pageRect.height * scale) / 2
            
            cgContext.translateBy(x: tx, y: ty)
            cgContext.scaleBy(x: scale, y: scale)
            
            page.draw(with: .mediaBox, to: cgContext)
            cgContext.restoreGState()
        }
    }
    
    private func drawImage(url: URL, to size: CGSize) -> UIImage? {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Static Default Templates List
    
    static var builtInTemplates: [PaperTemplate] {
        return [
            // Standard paper presets
            PaperTemplate(id: "blank", name: "Blank", subtitle: "Blank Paper", kind: .builtIn, source: .builtInVector, builtInPresetId: "blank", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "ruled", name: "Ruled", subtitle: "Lined Paper", kind: .builtIn, source: .builtInVector, builtInPresetId: "ruled", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "grid", name: "Grid", subtitle: "Grid Paper", kind: .builtIn, source: .builtInVector, builtInPresetId: "grid", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "dotGrid", name: "Dot Grid", subtitle: "Dotted Paper", kind: .builtIn, source: .builtInVector, builtInPresetId: "dotGrid", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "genkouYoushi", name: "Genkouyoushi", subtitle: "原稿用紙 Japanese Manuscript", kind: .builtIn, source: .builtInVector, builtInPresetId: "genkouYoushi", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "kana", name: "Kana Practice", subtitle: "かな Kana Practice Grid", kind: .builtIn, source: .builtInVector, builtInPresetId: "kana", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "kanji", name: "Kanji Practice", subtitle: "漢字 Kanji Practice Grid", kind: .builtIn, source: .builtInVector, builtInPresetId: "kanji", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            
            // New built-in study sheets
            PaperTemplate(id: "vocabTable", name: "Japanese Vocabulary Table", subtitle: "ตารางคำศัพท์ภาษาญี่ปุ่น (Japanese, Reading, Thai, Notes)", kind: .builtIn, source: .builtInVector, builtInPresetId: "vocabTable", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "simpleVocab", name: "Simple Vocabulary Sheet", subtitle: "แผ่นจดคำศัพท์ (Word, Reading, Romaji, Meaning, Example)", kind: .builtIn, source: .builtInVector, builtInPresetId: "simpleVocab", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "kanjiStudy", name: "Kanji Study Sheet", subtitle: "คันจิ แผ่นศึกษาและคัดอักษรรายตัว", kind: .builtIn, source: .builtInVector, builtInPresetId: "kanjiStudy", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "grammarPattern", name: "Grammar Pattern Sheet", subtitle: "แผ่นจดและวิเคราะห์โครงสร้างไวยากรณ์", kind: .builtIn, source: .builtInVector, builtInPresetId: "grammarPattern", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "sentencePractice", name: "Sentence Practice Sheet", subtitle: "ตารางแปลและแต่งประโยคคัดลายมือ", kind: .builtIn, source: .builtInVector, builtInPresetId: "sentencePractice", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "lessonSummary", name: "Lesson Summary Sheet", subtitle: "แผ่นสรุปหัวข้อและคำศัพท์ประจำบทเรียน", kind: .builtIn, source: .builtInVector, builtInPresetId: "lessonSummary", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "cornellNotes", name: "Cornell Notes", subtitle: "จดโน้ตสรุปแบ่งสัดส่วนคอร์เนล", kind: .builtIn, source: .builtInVector, builtInPresetId: "cornellNotes", isFavorite: false, createdAt: Date(), updatedAt: Date()),
            PaperTemplate(id: "dailyPlanner", name: "Daily Japanese Planner", subtitle: "แพลนเนอร์เรียนภาษาญี่ปุ่นประจำวัน", kind: .builtIn, source: .builtInVector, builtInPresetId: "dailyPlanner", isFavorite: false, createdAt: Date(), updatedAt: Date())
        ]
    }
}
