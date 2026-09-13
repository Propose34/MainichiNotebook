import Foundation
import Combine
import SwiftUI

@MainActor
final class WritingPracticeViewModel: ObservableObject {
    @Published var selectedMode: WritingPracticeMode = .hiragana {
        didSet {
            // Auto-select the first item in the new mode's filtered list if on iPad split-screen layout
            if selectedCharacterId != nil {
                selectedCharacterId = filteredCharacters.first?.id
            }
        }
    }
    @Published var selectedCharacterId: String? = nil
    @Published var searchText: String = ""
    
    private let repository: StudyDataRepository
    
    // Hiragana Gojuon Dataset
    private let hiraganaDataset: [WritingPracticeCharacter] = [
        // A Row
        WritingPracticeCharacter(id: "h_a", character: "あ", reading: "a", mode: .hiragana, group: "A Row"),
        WritingPracticeCharacter(id: "h_i", character: "い", reading: "i", mode: .hiragana, group: "A Row"),
        WritingPracticeCharacter(id: "h_u", character: "う", reading: "u", mode: .hiragana, group: "A Row"),
        WritingPracticeCharacter(id: "h_e", character: "え", reading: "e", mode: .hiragana, group: "A Row"),
        WritingPracticeCharacter(id: "h_o", character: "お", reading: "o", mode: .hiragana, group: "A Row"),
        
        // Ka Row
        WritingPracticeCharacter(id: "h_ka", character: "か", reading: "ka", mode: .hiragana, group: "Ka Row"),
        WritingPracticeCharacter(id: "h_ki", character: "き", reading: "ki", mode: .hiragana, group: "Ka Row"),
        WritingPracticeCharacter(id: "h_ku", character: "く", reading: "ku", mode: .hiragana, group: "Ka Row"),
        WritingPracticeCharacter(id: "h_ke", character: "け", reading: "ke", mode: .hiragana, group: "Ka Row"),
        WritingPracticeCharacter(id: "h_ko", character: "こ", reading: "ko", mode: .hiragana, group: "Ka Row"),
        
        // Sa Row
        WritingPracticeCharacter(id: "h_sa", character: "さ", reading: "sa", mode: .hiragana, group: "Sa Row"),
        WritingPracticeCharacter(id: "h_shi", character: "し", reading: "shi", mode: .hiragana, group: "Sa Row"),
        WritingPracticeCharacter(id: "h_su", character: "す", reading: "su", mode: .hiragana, group: "Sa Row"),
        WritingPracticeCharacter(id: "h_se", character: "せ", reading: "se", mode: .hiragana, group: "Sa Row"),
        WritingPracticeCharacter(id: "h_so", character: "そ", reading: "so", mode: .hiragana, group: "Sa Row"),
        
        // Ta Row
        WritingPracticeCharacter(id: "h_ta", character: "た", reading: "ta", mode: .hiragana, group: "Ta Row"),
        WritingPracticeCharacter(id: "h_chi", character: "ち", reading: "chi", mode: .hiragana, group: "Ta Row"),
        WritingPracticeCharacter(id: "h_tsu", character: "つ", reading: "tsu", mode: .hiragana, group: "Ta Row"),
        WritingPracticeCharacter(id: "h_te", character: "て", reading: "te", mode: .hiragana, group: "Ta Row"),
        WritingPracticeCharacter(id: "h_to", character: "と", reading: "to", mode: .hiragana, group: "Ta Row"),
        
        // Na Row
        WritingPracticeCharacter(id: "h_na", character: "な", reading: "na", mode: .hiragana, group: "Na Row"),
        WritingPracticeCharacter(id: "h_ni", character: "に", reading: "ni", mode: .hiragana, group: "Na Row"),
        WritingPracticeCharacter(id: "h_nu", character: "ぬ", reading: "nu", mode: .hiragana, group: "Na Row"),
        WritingPracticeCharacter(id: "h_ne", character: "ね", reading: "ne", mode: .hiragana, group: "Na Row"),
        WritingPracticeCharacter(id: "h_no", character: "の", reading: "no", mode: .hiragana, group: "Na Row"),
        
        // Ha Row
        WritingPracticeCharacter(id: "h_ha", character: "は", reading: "ha", mode: .hiragana, group: "Ha Row"),
        WritingPracticeCharacter(id: "h_hi", character: "ひ", reading: "hi", mode: .hiragana, group: "Ha Row"),
        WritingPracticeCharacter(id: "h_fu", character: "ふ", reading: "fu", mode: .hiragana, group: "Ha Row"),
        WritingPracticeCharacter(id: "h_he", character: "へ", reading: "he", mode: .hiragana, group: "Ha Row"),
        WritingPracticeCharacter(id: "h_ho", character: "ほ", reading: "ho", mode: .hiragana, group: "Ha Row"),
        
        // Ma Row
        WritingPracticeCharacter(id: "h_ma", character: "ま", reading: "ma", mode: .hiragana, group: "Ma Row"),
        WritingPracticeCharacter(id: "h_mi", character: "み", reading: "mi", mode: .hiragana, group: "Ma Row"),
        WritingPracticeCharacter(id: "h_mu", character: "む", reading: "mu", mode: .hiragana, group: "Ma Row"),
        WritingPracticeCharacter(id: "h_me", character: "め", reading: "me", mode: .hiragana, group: "Ma Row"),
        WritingPracticeCharacter(id: "h_mo", character: "も", reading: "mo", mode: .hiragana, group: "Ma Row"),
        
        // Ya Row
        WritingPracticeCharacter(id: "h_ya", character: "や", reading: "ya", mode: .hiragana, group: "Ya Row"),
        WritingPracticeCharacter(id: "h_yu", character: "ゆ", reading: "yu", mode: .hiragana, group: "Ya Row"),
        WritingPracticeCharacter(id: "h_yo", character: "よ", reading: "yo", mode: .hiragana, group: "Ya Row"),
        
        // Ra Row
        WritingPracticeCharacter(id: "h_ra", character: "ら", reading: "ra", mode: .hiragana, group: "Ra Row"),
        WritingPracticeCharacter(id: "h_ri", character: "り", reading: "ri", mode: .hiragana, group: "Ra Row"),
        WritingPracticeCharacter(id: "h_ru", character: "る", reading: "ru", mode: .hiragana, group: "Ra Row"),
        WritingPracticeCharacter(id: "h_re", character: "れ", reading: "re", mode: .hiragana, group: "Ra Row"),
        WritingPracticeCharacter(id: "h_ro", character: "ろ", reading: "ro", mode: .hiragana, group: "Ra Row"),
        
        // Wa Row
        WritingPracticeCharacter(id: "h_wa", character: "わ", reading: "wa", mode: .hiragana, group: "Wa Row"),
        WritingPracticeCharacter(id: "h_wo", character: "を", reading: "wo", mode: .hiragana, group: "Wa Row"),
        WritingPracticeCharacter(id: "h_n", character: "ん", reading: "n", mode: .hiragana, group: "Wa Row")
    ]
    
    // Katakana Gojuon Dataset
    private let katakanaDataset: [WritingPracticeCharacter] = [
        // A Row
        WritingPracticeCharacter(id: "k_a", character: "ア", reading: "a", mode: .katakana, group: "A Row"),
        WritingPracticeCharacter(id: "k_i", character: "イ", reading: "i", mode: .katakana, group: "A Row"),
        WritingPracticeCharacter(id: "k_u", character: "ウ", reading: "u", mode: .katakana, group: "A Row"),
        WritingPracticeCharacter(id: "k_e", character: "エ", reading: "e", mode: .katakana, group: "A Row"),
        WritingPracticeCharacter(id: "k_o", character: "オ", reading: "o", mode: .katakana, group: "A Row"),
        
        // Ka Row
        WritingPracticeCharacter(id: "k_ka", character: "カ", reading: "ka", mode: .katakana, group: "Ka Row"),
        WritingPracticeCharacter(id: "k_ki", character: "キ", reading: "ki", mode: .katakana, group: "Ka Row"),
        WritingPracticeCharacter(id: "k_ku", character: "ク", reading: "ku", mode: .katakana, group: "Ka Row"),
        WritingPracticeCharacter(id: "k_ke", character: "ケ", reading: "ke", mode: .katakana, group: "Ka Row"),
        WritingPracticeCharacter(id: "k_ko", character: "コ", reading: "ko", mode: .katakana, group: "Ka Row"),
        
        // Sa Row
        WritingPracticeCharacter(id: "k_sa", character: "サ", reading: "sa", mode: .katakana, group: "Sa Row"),
        WritingPracticeCharacter(id: "k_shi", character: "シ", reading: "shi", mode: .katakana, group: "Sa Row"),
        WritingPracticeCharacter(id: "k_su", character: "ス", reading: "su", mode: .katakana, group: "Sa Row"),
        WritingPracticeCharacter(id: "k_se", character: "セ", reading: "se", mode: .katakana, group: "Sa Row"),
        WritingPracticeCharacter(id: "k_so", character: "ソ", reading: "so", mode: .katakana, group: "Sa Row"),
        
        // Ta Row
        WritingPracticeCharacter(id: "k_ta", character: "タ", reading: "ta", mode: .katakana, group: "Ta Row"),
        WritingPracticeCharacter(id: "k_chi", character: "チ", reading: "chi", mode: .katakana, group: "Ta Row"),
        WritingPracticeCharacter(id: "k_tsu", character: "ツ", reading: "tsu", mode: .katakana, group: "Ta Row"),
        WritingPracticeCharacter(id: "k_te", character: "テ", reading: "te", mode: .katakana, group: "Ta Row"),
        WritingPracticeCharacter(id: "k_to", character: "ト", reading: "to", mode: .katakana, group: "Ta Row"),
        
        // Na Row
        WritingPracticeCharacter(id: "k_na", character: "ナ", reading: "na", mode: .katakana, group: "Na Row"),
        WritingPracticeCharacter(id: "k_ni", character: "ニ", reading: "ni", mode: .katakana, group: "Na Row"),
        WritingPracticeCharacter(id: "k_nu", character: "ヌ", reading: "nu", mode: .katakana, group: "Na Row"),
        WritingPracticeCharacter(id: "k_ne", character: "ネ", reading: "ne", mode: .katakana, group: "Na Row"),
        WritingPracticeCharacter(id: "k_no", character: "ノ", reading: "no", mode: .katakana, group: "Na Row"),
        
        // Ha Row
        WritingPracticeCharacter(id: "k_ha", character: "ハ", reading: "ha", mode: .katakana, group: "Ha Row"),
        WritingPracticeCharacter(id: "k_hi", character: "ヒ", reading: "hi", mode: .katakana, group: "Ha Row"),
        WritingPracticeCharacter(id: "k_fu", character: "フ", reading: "fu", mode: .katakana, group: "Ha Row"),
        WritingPracticeCharacter(id: "k_he", character: "ヘ", reading: "he", mode: .katakana, group: "Ha Row"),
        WritingPracticeCharacter(id: "k_ho", character: "ホ", reading: "ho", mode: .katakana, group: "Ha Row"),
        
        // Ma Row
        WritingPracticeCharacter(id: "k_ma", character: "マ", reading: "ma", mode: .katakana, group: "Ma Row"),
        WritingPracticeCharacter(id: "k_mi", character: "ミ", reading: "mi", mode: .katakana, group: "Ma Row"),
        WritingPracticeCharacter(id: "k_mu", character: "ム", reading: "mu", mode: .katakana, group: "Ma Row"),
        WritingPracticeCharacter(id: "k_me", character: "メ", reading: "me", mode: .katakana, group: "Ma Row"),
        WritingPracticeCharacter(id: "k_mo", character: "モ", reading: "mo", mode: .katakana, group: "Ma Row"),
        
        // Ya Row
        WritingPracticeCharacter(id: "k_ya", character: "ヤ", reading: "ya", mode: .katakana, group: "Ya Row"),
        WritingPracticeCharacter(id: "k_yu", character: "ユ", reading: "yu", mode: .katakana, group: "Ya Row"),
        WritingPracticeCharacter(id: "k_yo", character: "ヨ", reading: "yo", mode: .katakana, group: "Ya Row"),
        
        // Ra Row
        WritingPracticeCharacter(id: "k_ra", character: "ラ", reading: "ra", mode: .katakana, group: "Ra Row"),
        WritingPracticeCharacter(id: "k_ri", character: "リ", reading: "ri", mode: .katakana, group: "Ra Row"),
        WritingPracticeCharacter(id: "k_ru", character: "ル", reading: "ru", mode: .katakana, group: "Ra Row"),
        WritingPracticeCharacter(id: "k_re", character: "レ", reading: "re", mode: .katakana, group: "Ra Row"),
        WritingPracticeCharacter(id: "k_ro", character: "ロ", reading: "ro", mode: .katakana, group: "Ra Row"),
        
        // Wa Row
        WritingPracticeCharacter(id: "k_wa", character: "ワ", reading: "wa", mode: .katakana, group: "Wa Row"),
        WritingPracticeCharacter(id: "k_wo", character: "ヲ", reading: "wo", mode: .katakana, group: "Wa Row"),
        WritingPracticeCharacter(id: "k_n", character: "ン", reading: "n", mode: .katakana, group: "Wa Row")
    ]
    
    init(service: StudyDataService) {
        self.repository = StudyDataRepository(service: service)
    }
    
    var filteredCharacters: [WritingPracticeCharacter] {
        switch selectedMode {
        case .hiragana:
            if searchText.isEmpty {
                return hiraganaDataset
            } else {
                let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return hiraganaDataset.filter {
                    $0.character.contains(query) || $0.reading.lowercased().contains(query) || $0.group.lowercased().contains(query)
                }
            }
        case .katakana:
            if searchText.isEmpty {
                return katakanaDataset
            } else {
                let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return katakanaDataset.filter {
                    $0.character.contains(query) || $0.reading.lowercased().contains(query) || $0.group.lowercased().contains(query)
                }
            }
        case .kanji:
            let kanjis = repository.allKanjiItems().map { $0.toWritingPracticeCharacter() }
            if searchText.isEmpty {
                return kanjis
            } else {
                let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return kanjis.filter {
                    $0.character.contains(query) ||
                    $0.reading.lowercased().contains(query) ||
                    ($0.meaning ?? "").lowercased().contains(query) ||
                    $0.group.lowercased().contains(query)
                }
            }
        }
    }
    
    var selectedCharacter: WritingPracticeCharacter? {
        guard let id = selectedCharacterId else { return nil }
        // Look up in unfiltered datasets to ensure we find it even if searching/filtering is active
        return character(forId: id)
    }
    
    func character(forId id: String) -> WritingPracticeCharacter? {
        if id.hasPrefix("h_") {
            return hiraganaDataset.first(where: { $0.id == id })
        } else if id.hasPrefix("k_") {
            return katakanaDataset.first(where: { $0.id == id })
        } else if id.hasPrefix("kanji_") {
            // Retrieve from all kanji items directly to avoid search filters
            return repository.allKanjiItems().map { $0.toWritingPracticeCharacter() }.first(where: { $0.id == id })
        }
        return nil
    }
    
    var totalCountForCurrentMode: Int {
        switch selectedMode {
        case .hiragana: return hiraganaDataset.count
        case .katakana: return katakanaDataset.count
        case .kanji: return repository.allKanjiItems().count
        }
    }
}

extension KanjiItem {
    func toWritingPracticeCharacter() -> WritingPracticeCharacter {
        return WritingPracticeCharacter(
            id: "kanji_\(id)",
            character: kanji,
            reading: reading,
            meaning: meaningTh,
            mode: .kanji,
            group: level ?? "N5",
            exampleJp: exampleJp,
            exampleTh: exampleTh,
            notes: builderPattern
        )
    }
}

