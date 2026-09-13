import SwiftUI
import PDFKit

struct PDFPageBackgroundView: View {
    let pdfURL: URL
    let pageIndex: Int
    let canvasSize: CGSize
    
    @State private var renderedImage: UIImage? = nil
    
    var body: some View {
        Group {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                VStack {
                    ProgressView()
                    Text("Loading PDF Page...")
                        .font(AppTheme.fontRounded(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
                .onAppear {
                    render()
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .onChange(of: pageIndex) { _ in
            render()
        }
    }
    
    private func render() {
        renderedImage = nil // Reset old page cache
        let targetIndex = pageIndex
        DispatchQueue.global(qos: .userInitiated).async {
            let img = drawPDFPage(from: pdfURL, pageIndex: targetIndex, size: canvasSize)
            DispatchQueue.main.async {
                if targetIndex == self.pageIndex {
                    if let rendered = img {
                        self.renderedImage = rendered
                    } else {
                        self.renderedImage = self.createBlankWhiteImage(size: canvasSize)
                    }
                }
            }
        }
    }
    
    private func createBlankWhiteImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private func drawPDFPage(from url: URL, pageIndex: Int, size: CGSize) -> UIImage? {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: pageIndex) else {
            return nil
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // White base
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // CoreGraphics rendering transform coordinate system flip
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            let scaleX = size.width / pageRect.width
            let scaleY = size.height / pageRect.height
            let scale = min(scaleX, scaleY)
            
            let tx = (size.width - pageRect.width * scale) / 2
            let ty = (size.height - pageRect.height * scale) / 2
            
            ctx.cgContext.translateBy(x: tx, y: ty)
            ctx.cgContext.scaleBy(x: scale, y: scale)
            
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}
extension PDFPageBackgroundView: Equatable {
    static func == (lhs: PDFPageBackgroundView, rhs: PDFPageBackgroundView) -> Bool {
        lhs.pdfURL == rhs.pdfURL && lhs.pageIndex == rhs.pageIndex && lhs.canvasSize == rhs.canvasSize
    }
}
