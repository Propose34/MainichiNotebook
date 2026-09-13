import SwiftUI

struct AnnotationRenderView: View {
    let item: AnnotationItem
    let bookId: UUID
    
    var body: some View {
        let currentWidth = CGFloat(item.width)
        let currentHeight = CGFloat(item.height)
        let currentX = CGFloat(item.xOffset)
        let currentY = CGFloat(item.yOffset)
        
        return Group {
            switch item.type {
            case .sticker:
                Text(item.content)
                    .font(.system(size: 40))
                    .frame(width: currentWidth, height: currentHeight)
                
            case .postIt:
                VStack(alignment: .leading) {
                    Text(item.content)
                        .font(AppTheme.fontRounded(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textDark)
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(width: currentWidth, height: currentHeight)
                .background(Color(hex: "FFF9AE")) // Traditional soft Post-it yellow
                .cornerRadius(4)
                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                
            case .image:
                let url = LectureStorageService.shared.getImageUrl(bookId: bookId, imageName: item.content)
                if let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: currentWidth, height: currentHeight)
                        .clipped()
                        .cornerRadius(4)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: currentWidth, height: currentHeight)
                }

            case .text:
                // Plain movable text label — rendered as-is for export
                Text(item.content.isEmpty ? "" : item.content)
                    .font(AppTheme.fontRounded(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textDark)
                    .padding(6)
                    .frame(width: currentWidth, height: currentHeight, alignment: .topLeading)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(4)
            }
        }
        .position(x: currentX + currentWidth / 2, y: currentY + currentHeight / 2)
    }
}
