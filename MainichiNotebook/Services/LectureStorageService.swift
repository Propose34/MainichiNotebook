import Foundation
import PencilKit
import PDFKit
import ImageIO

class LectureStorageService {
    static let shared = LectureStorageService()
    
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var booksDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Books", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }
    
    private func bookDirectory(for bookId: UUID) -> URL {
        let url = booksDirectory.appendingPathComponent(bookId.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            
            // Create nested directory paths
            try? fileManager.createDirectory(at: url.appendingPathComponent("drawings"), withIntermediateDirectories: true)
            try? fileManager.createDirectory(at: url.appendingPathComponent("images"), withIntermediateDirectories: true)
            try? fileManager.createDirectory(at: url.appendingPathComponent("attachments"), withIntermediateDirectories: true)
        }
        return url
    }
    
    // MARK: - Book management
    
    func loadBooks() -> [LectureBook] {
        let metadataURL = booksDirectory.appendingPathComponent("metadata.json")
        if fileManager.fileExists(atPath: metadataURL.path),
           let data = try? Data(contentsOf: metadataURL),
           let books = try? JSONDecoder().decode([LectureBook].self, from: data) {
            return books
        }
        
        // Initial fallback load: Populate with default starter books
        let defaultBooks = MockData.lectureBooks
        saveBooks(defaultBooks)
        return defaultBooks
    }
    
    func saveBooks(_ books: [LectureBook]) {
        let metadataURL = booksDirectory.appendingPathComponent("metadata.json")
        if let data = try? JSONEncoder().encode(books) {
            try? data.write(to: metadataURL)
        }
    }
    
    func saveBook(_ book: LectureBook) {
        var books = loadBooks()
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        } else {
            books.append(book)
        }
        saveBooks(books)
    }
    
    // MARK: - Page management
    
    func loadPages(for bookId: UUID) -> [LecturePage] {
        let bookDir = bookDirectory(for: bookId)
        let pagesURL = bookDir.appendingPathComponent("pages.json")
        if fileManager.fileExists(atPath: pagesURL.path),
           let data = try? Data(contentsOf: pagesURL),
           let pages = try? JSONDecoder().decode([LecturePage].self, from: data) {
            return pages.sorted(by: { $0.pageNumber < $1.pageNumber })
        }
        
        // Pre-create initial pages for newly created notebook
        let initialPages = [
            LecturePage(pageNumber: 1),
            LecturePage(pageNumber: 2),
            LecturePage(pageNumber: 3)
        ]
        savePages(initialPages, for: bookId)
        return initialPages
    }
    
    func savePages(_ pages: [LecturePage], for bookId: UUID) {
        let bookDir = bookDirectory(for: bookId)
        let pagesURL = bookDir.appendingPathComponent("pages.json")
        if let data = try? JSONEncoder().encode(pages) {
            try? data.write(to: pagesURL)
        }
    }
    
    // MARK: - Drawing management
    
    func loadDrawing(bookId: UUID, pageId: UUID) -> PKDrawing {
        let bookDir = bookDirectory(for: bookId)
        let drawingURL = bookDir.appendingPathComponent("drawings").appendingPathComponent("\(pageId.uuidString).bin")
        if fileManager.fileExists(atPath: drawingURL.path),
           let data = try? Data(contentsOf: drawingURL),
           let drawing = try? PKDrawing(data: data) {
            return drawing
        }
        return PKDrawing()
    }
    
    func saveDrawing(_ drawing: PKDrawing, bookId: UUID, pageId: UUID) {
        let bookDir = bookDirectory(for: bookId)
        let drawingURL = bookDir.appendingPathComponent("drawings").appendingPathComponent("\(pageId.uuidString).bin")
        let data = drawing.dataRepresentation()
        try? data.write(to: drawingURL)
    }
    
    // MARK: - Image insertion persistence & Caching
    
    private var imageCache = NSCache<NSString, UIImage>()
    
    func saveInsertedImage(data: Data, bookId: UUID, imageName: String) -> URL? {
        let bookDir = bookDirectory(for: bookId)
        let imageURL = bookDir.appendingPathComponent("images").appendingPathComponent(imageName)
        do {
            try data.write(to: imageURL)
            // Clear any old cache entry if it existed
            let cacheKey = "\(bookId.uuidString)_\(imageName)" as NSString
            imageCache.removeObject(forKey: cacheKey)
            return imageURL
        } catch {
            print("Error writing inserted image file: \(error)")
            return nil
        }
    }
    
    func getImageUrl(bookId: UUID, imageName: String) -> URL {
        let bookDir = bookDirectory(for: bookId)
        return bookDir.appendingPathComponent("images").appendingPathComponent(imageName)
    }
    
    func getCachedImage(bookId: UUID, imageName: String) -> UIImage? {
        let cacheKey = "\(bookId.uuidString)_\(imageName)" as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        
        let url = getImageUrl(bookId: bookId, imageName: imageName)
        guard fileManager.fileExists(atPath: url.path),
              let rawImage = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        // For smooth dragging and low memory usage in editor, downsample to 2x thumbnail scale (440x330)
        let targetSize = CGSize(width: 440, height: 330)
        let downsampled = downsample(imageAt: url, to: targetSize) ?? rawImage
        
        imageCache.setObject(downsampled, forKey: cacheKey)
        return downsampled
    }
    
    private func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat = 2.0) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as [CFString: Any] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    // MARK: - File Attachment persistence
    
    func saveAttachment(fileURL: URL, bookId: UUID) -> AttachmentItem? {
        let shouldAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let bookDir = bookDirectory(for: bookId)
        let fileName = fileURL.lastPathComponent
        let targetURL = bookDir.appendingPathComponent("attachments").appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: targetURL.path) {
                try? fileManager.removeItem(at: targetURL)
            }
            try fileManager.copyItem(at: fileURL, to: targetURL)
            return AttachmentItem(fileName: fileName, localPath: "attachments/\(fileName)")
        } catch {
            print("Error copying file attachment: \(error)")
            return nil
        }
    }
    
    func getAttachmentUrl(bookId: UUID, relativePath: String) -> URL {
        let bookDir = bookDirectory(for: bookId)
        let fileName = (relativePath as NSString).lastPathComponent
        return bookDir.appendingPathComponent("attachments").appendingPathComponent(fileName)
    }
    
    // MARK: - PDF Library Imports
    
    func importPDF(from fileURL: URL) -> LectureBook? {
        let shouldAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let bookId = UUID()
        let bookDir = bookDirectory(for: bookId)
        let fileName = fileURL.lastPathComponent
        let targetPDFURL = bookDir.appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: targetPDFURL.path) {
                try? fileManager.removeItem(at: targetPDFURL)
            }
            try fileManager.copyItem(at: fileURL, to: targetPDFURL)
            
            // Check page count using PDFDocument
            var pagesCount = 1
            if let doc = PDFDocument(url: targetPDFURL) {
                pagesCount = doc.pageCount
            }
            
            let title = fileURL.deletingPathExtension().lastPathComponent
            let newBook = LectureBook(
                id: bookId,
                title: title,
                subtitle: "Imported PDF",
                coverColorHex: "DFD7C7", // Muted beige PDF cover
                progress: 0.0,
                subject: "PDF Import",
                isFavorite: false,
                isCompleted: false,
                decorationEmoji: "📄",
                isPDF: true,
                pdfFileName: fileName
            )
            
            // Pre-create LecturePage templates matching the PDF's page count
            var pages: [LecturePage] = []
            for i in 0..<pagesCount {
                pages.append(LecturePage(pageNumber: i + 1, pdfPageNumber: i))
            }
            savePages(pages, for: bookId)
            saveBook(newBook)
            
            return newBook
        } catch {
            print("Error copying imported PDF: \(error)")
            return nil
        }
    }
    
    func importPDFPages(from fileURL: URL, into book: LectureBook, startingPageNumber: Int) -> (updatedBook: LectureBook, importedPages: [LecturePage])? {
        let shouldAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let bookDir = bookDirectory(for: book.id)
        let fileName = fileURL.lastPathComponent
        let targetPDFURL = bookDir.appendingPathComponent(fileName)
        
        // Ensure directories exist
        try? fileManager.createDirectory(at: bookDir, withIntermediateDirectories: true, attributes: nil)
        
        do {
            if fileManager.fileExists(atPath: targetPDFURL.path) {
                try? fileManager.removeItem(at: targetPDFURL)
            }
            try fileManager.copyItem(at: fileURL, to: targetPDFURL)
            
            // Check page count using PDFDocument
            var pagesCount = 1
            if let doc = PDFDocument(url: targetPDFURL) {
                pagesCount = doc.pageCount
            }
            
            var updatedBook = book
            updatedBook.isPDF = true
            updatedBook.pdfFileName = fileName
            saveBook(updatedBook)
            
            var importedPages: [LecturePage] = []
            for i in 0..<pagesCount {
                importedPages.append(LecturePage(
                    pageNumber: startingPageNumber + i,
                    pdfPageNumber: i,
                    paperPreset: .blank
                ))
            }
            
            return (updatedBook, importedPages)
        } catch {
            print("Error importing PDF pages: \(error)")
            return nil
        }
    }
    
    func getPDFUrl(bookId: UUID, pdfFileName: String) -> URL {
        let bookDir = bookDirectory(for: bookId)
        return bookDir.appendingPathComponent(pdfFileName)
    }
    
    func deleteBook(id: UUID) {
        // 1. Remove from metadata list
        var books = loadBooks()
        books.removeAll(where: { $0.id == id })
        saveBooks(books)
        
        // 2. Physically remove the book directory containing drawings, attachments, and pages.json
        let bookDir = bookDirectory(for: id)
        if fileManager.fileExists(atPath: bookDir.path) {
            try? fileManager.removeItem(at: bookDir)
        }
    }
}
