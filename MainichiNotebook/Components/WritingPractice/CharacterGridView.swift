import SwiftUI

struct CharacterGridView: View {
    let characters: [WritingPracticeCharacter]
    let selectedId: String?
    let progressService: WritingPracticeProgressService
    let onSelect: (WritingPracticeCharacter) -> Void
    
    private var groupedCharacters: [(groupName: String, items: [WritingPracticeCharacter])] {
        var groups: [String: [WritingPracticeCharacter]] = [:]
        var order: [String] = []
        for char in characters {
            let grp = char.group
            if groups[grp] == nil {
                groups[grp] = []
                order.append(grp)
            }
            groups[grp]?.append(char)
        }
        // Preserve original insertion order for static tables
        return order.map { (groupName: $0, items: groups[$0] ?? []) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groupedCharacters, id: \.groupName) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.groupName.uppercased())
                            .font(AppTheme.fontRounded(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.8))
                            .padding(.horizontal, 4)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 65))], spacing: 10) {
                            ForEach(group.items) { item in
                                CharacterPracticeCardView(
                                    character: item,
                                    isSelected: selectedId == item.id,
                                    practiceCount: progressService.practiceCount(for: item.id),
                                    action: {
                                        onSelect(item)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
}
