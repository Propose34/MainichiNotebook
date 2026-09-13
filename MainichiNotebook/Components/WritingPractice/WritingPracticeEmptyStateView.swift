import SwiftUI

struct WritingPracticeEmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        EmptyStateCardView(
            iconName: "pencil.and.outline",
            title: "Select a character to start",
            description: "Tap on any hiragana, katakana, or kanji character from the list on the left to open the guided tracing canvas."
        )
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground)
    }
}
