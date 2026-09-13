import SwiftUI

/// Typed-text Post-it note annotation.
/// Supports text editing when isSelectMoveMode is active.
/// Note: Handwritten post-it (embedded PKCanvas) is planned for a future phase.
struct PostItView: View {
    @Binding var text: String
    var isSelectMoveMode: Bool      // True when Select/Move tool is active

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tape strip decoration
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "EAE5DB").opacity(0.85))
                    .frame(width: 44, height: 8)
                Spacer()
            }
            .padding(.bottom, 4)

            if isSelectMoveMode {
                TextEditor(text: $text)
                    .font(AppTheme.fontRounded(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textDark)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(text.isEmpty ? "Tap Select to edit…" : text)
                    .font(AppTheme.fontRounded(size: 13, weight: .medium))
                    .foregroundColor(text.isEmpty ? AppTheme.textMuted : AppTheme.textDark)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .lineSpacing(3)
            }
        }
        .padding(10)
        .background(Color(hex: "FDF7E7"))     // Classic soft yellow
        .cornerRadius(3)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 1, y: 2)
    }
}
