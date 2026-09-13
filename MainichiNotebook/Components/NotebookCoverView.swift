import SwiftUI

struct NotebookCoverView: View {
    let book: LectureBook
    var size: CGSize = CGSize(width: 105, height: 145)
    
    private var pageInfo: (pageCount: Int, attachmentCount: Int) {
        let pages = LectureStorageService.shared.loadPages(for: book.id)
        let attachCount = pages.reduce(0) { $0 + $1.attachments.count }
        return (pages.count, attachCount)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main Cover Card
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: book.coverColorHex))
                .frame(width: size.width, height: size.height)
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 2, y: 3)
            
            // Spine Shadow/Texture Overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.2), Color.white.opacity(0.08), Color.black.opacity(0.02)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width * 0.12, height: size.height)
                .cornerRadius(8, corners: [.topLeft, .bottomLeft])
            
            // Spine Binding Lines (Stitch-like)
            Rectangle()
                .stroke(Color.black.opacity(0.15), lineWidth: 0.8)
                .frame(width: size.width * 0.08, height: size.height)
            
            // Gold Ornaments & Inner Frame
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "D8C090").opacity(0.65), lineWidth: 0.8)
                .padding(4)
                .frame(width: size.width, height: size.height)
            
            // Book Titles & Info
            VStack(alignment: .center, spacing: 4) {
                // Topic Emoji
                Text(book.decorationEmoji)
                    .font(.system(size: 20))
                    .padding(.top, 14)
                
                Spacer()
                
                // English Title
                Text(book.title)
                    .font(AppTheme.fontSerif(size: 11, weight: .bold))
                    .foregroundColor(textColorForCover)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                
                // Japanese Subtitle
                Text(book.subtitle)
                    .font(AppTheme.fontSerif(size: 9, weight: .medium))
                    .foregroundColor(textColorForCover.opacity(0.8))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                
                Spacer()
                
                // Meta Info List at the bottom (removes misleading progress percentages)
                let info = pageInfo
                let pagesText = "\(info.pageCount) page" + (info.pageCount == 1 ? "" : "s")
                VStack(spacing: 2) {
                    Text(book.subject)
                        .font(AppTheme.fontRounded(size: 8, weight: .bold))
                        .foregroundColor(textColorForCover.opacity(0.75))
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(pagesText)
                            .font(AppTheme.fontRounded(size: 7, weight: .regular))
                            .foregroundColor(textColorForCover.opacity(0.7))
                        
                        if info.attachmentCount > 0 {
                            Text("•")
                                .font(.system(size: 6))
                                .foregroundColor(textColorForCover.opacity(0.5))
                            Text("\(info.attachmentCount) 📎")
                                .font(AppTheme.fontRounded(size: 7, weight: .regular))
                                .foregroundColor(textColorForCover.opacity(0.7))
                        }
                    }
                    
                    if book.isPDF {
                        Text("PDF Notes")
                            .font(AppTheme.fontRounded(size: 7, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(4)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
            .frame(width: size.width, height: size.height)
        }
    }
    
    // Choose appropriate text contrast depending on the book color
    private var textColorForCover: Color {
        let darkCovers = ["1C2A3A", "131B26"]
        if darkCovers.contains(book.coverColorHex.uppercased()) {
            return AppTheme.paperBackground
        } else {
            return AppTheme.textDark
        }
    }
}

// Rounded corners extension to round specific corners in SwiftUI
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
