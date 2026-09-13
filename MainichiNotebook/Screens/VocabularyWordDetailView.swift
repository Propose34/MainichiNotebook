import SwiftUI

struct VocabularyWordDetailView: View {
    let item: VocabularyItem
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.paperBackground.ignoresSafeArea()
            
            VocabularyDetailPanelView(item: item)
        }
        .navigationTitle(item.japanese)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Back")
                            .font(AppTheme.fontRounded(size: 15))
                    }
                    .foregroundColor(AppTheme.sakuraPink)
                }
            }
        }
    }
}
