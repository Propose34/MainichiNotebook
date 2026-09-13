import Foundation

struct FlashcardPrompt: Codable, Identifiable, Hashable {
    let id: String
    let targetType: StudyDataTargetType
    let targetId: String
    let promptType: String
    let prompt: String
    let choices: [String]
    let correctAnswer: String
    let explanationTh: String?
    let sourceFiles: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case targetType = "target_type"
        case targetId = "target_id"
        case promptType = "prompt_type"
        case prompt
        case choices
        case correctAnswer = "correct_answer"
        case explanationTh = "explanation_th"
        case sourceFiles = "source_files"
    }
}
