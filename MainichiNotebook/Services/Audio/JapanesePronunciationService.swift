import Foundation
import AVFoundation

final class JapanesePronunciationService {
    static let shared = JapanesePronunciationService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    /// Speaks the vocabulary item's Japanese characters, falling back to Hiragana reading.
    /// Returns true if speech started successfully, false if the voice was unavailable.
    func speakVocabulary(_ item: VocabularyItem) -> Bool {
        let textToSpeak: String
        if item.status == "custom" {
            let jpText = item.japanese.trimmingCharacters(in: .whitespacesAndNewlines)
            if !jpText.isEmpty {
                textToSpeak = jpText
            } else {
                textToSpeak = item.reading.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            let text = item.reading.trimmingCharacters(in: .whitespacesAndNewlines)
            textToSpeak = text.isEmpty ? item.japanese : text
        }
        
        return speakText(textToSpeak)
    }
    
    /// Speaks any Japanese text string directly.
    func speakText(_ text: String) -> Bool {
        stop()
        
        let textToSpeak = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSpeak.isEmpty else {
            return false
        }
        
        let utterance = AVSpeechUtterance(string: textToSpeak)
        
        let jaVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "ja-JP" }
        
        // Prioritize highest quality Japanese voices: Premium -> Enhanced -> Standard fallback
        let voice: AVSpeechSynthesisVoice? = {
            if #available(iOS 16.0, *) {
                if let premium = jaVoices.first(where: { $0.quality == .premium }) {
                    return premium
                }
            }
            if let enhanced = jaVoices.first(where: { $0.quality == .enhanced }) {
                return enhanced
            }
            return AVSpeechSynthesisVoice(language: "ja-JP")
        }()
        
        guard let voiceToUse = voice else {
            print("[JapanesePronunciationService] ja-JP voice is not installed or available on this device.")
            return false
        }
        
        utterance.voice = voiceToUse
        utterance.rate = 0.48 // Balanced pace (between 0.45 slow and 0.50 default) for natural flow
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
        return true
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

