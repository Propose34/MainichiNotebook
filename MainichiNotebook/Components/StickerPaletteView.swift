import SwiftUI

struct StickerPaletteView: View {
    @Binding var isPresented: Bool
    var onSelectSticker: (String) -> Void
    
    let emojis = ["🌸", "🌿", "🎌", "⛩️", "🦊", "🏮", "🍣", "🍵", "🗻", "🇯🇵", "📚", "✍️", "⭐", "✅", "💡", "🎯"]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Select Sticker")
                    .font(AppTheme.fontRounded(size: 16, weight: .bold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textMuted.opacity(0.5))
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        onSelectSticker(emoji)
                        isPresented = false
                    }) {
                        Text(emoji)
                            .font(.system(size: 32))
                            .padding(8)
                            .background(AppTheme.paperBeige.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(AppTheme.paperBackground)
        .cornerRadius(20)
    }
}
