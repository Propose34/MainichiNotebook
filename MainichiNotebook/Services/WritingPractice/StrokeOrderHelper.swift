import Foundation

struct StrokeOrderHelper {
    static func strokeGuide(for character: String) -> [String]? {
        switch character {
        // --- Hiragana A Row ---
        case "あ":
            return [
                "1. Short horizontal line from left to right.",
                "2. Vertical stroke curving down-left, cutting through the first line.",
                "3. Wide loop starting at the center, looping down, left, and sweeping right."
            ]
        case "い":
            return [
                "1. Curved stroke downward on the left, ending with a tiny upward hook.",
                "2. Shorter parallel curved stroke downward on the right."
            ]
        case "う":
            return [
                "1. Short diagonal hook/dot at the top.",
                "2. Large open curved loop/crescent at the bottom."
            ]
        case "え":
            return [
                "1. Short diagonal stroke at the top.",
                "2. A continuous zigzag stroke moving right, diagonally down-left, up-right, and ending in a rightward curve."
            ]
        case "お":
            return [
                "1. Short horizontal line from left to right.",
                "2. Vertical stroke down, looping left-up-right, then sweeping widely down and right.",
                "3. Small diagonal dot at the top-right."
            ]
            
        // --- Hiragana Ka Row ---
        case "か":
            return [
                "1. Horizontal line bending down-left with a bottom hook.",
                "2. Shorter diagonal line passing through the first stroke.",
                "3. Small diagonal dot on the top-right."
            ]
        case "き":
            return [
                "1. Short horizontal line left-to-right.",
                "2. Parallel horizontal line below it.",
                "3. Diagonal line cutting through both, ending with a rightward hook.",
                "4. Curved detached stroke at the bottom."
            ]
        case "く":
            return [
                "1. Single continuous stroke shaped like a sideways chevron pointing left (down-left, then down-right)."
            ]
        case "け":
            return [
                "1. Vertical line downward on the left, ending with an upward hook.",
                "2. Short horizontal line at the top-right.",
                "3. Vertical line cutting through the horizontal line, curving down-left."
            ]
        case "こ":
            return [
                "1. Top horizontal line curving right and hooking back.",
                "2. Bottom horizontal line curving slightly left."
            ]
            
        // --- Hiragana Sa Row ---
        case "さ":
            return [
                "1. Short horizontal stroke.",
                "2. Diagonal line cutting through it, hooking up-right.",
                "3. Curved detached stroke at the bottom."
            ]
        case "し":
            return [
                "1. Single vertical line down, curving smoothly up-right (like a fishhook)."
            ]
        case "す":
            return [
                "1. Horizontal stroke left-to-right.",
                "2. Vertical line down, forming a small circular loop to the left-up-right, and continuing down-left."
            ]
        case "せ":
            return [
                "1. Horizontal stroke left-to-right.",
                "2. Short vertical stroke on the right, ending with an upward hook.",
                "3. Long vertical stroke on the left, curving right at the bottom."
            ]
        case "そ":
            return [
                "1. Single continuous line zigzagging right, down-left, right, and ending in a curve down-left."
            ]
            
        // --- Katakana A Row ---
        case "ア":
            return [
                "1. Horizontal stroke left-to-right, then bending down-left.",
                "2. Curved vertical line down-left from the bend."
            ]
        case "イ":
            return [
                "1. Left-downward diagonal stroke.",
                "2. Vertical stroke down starting from the center of the first stroke."
            ]
        case "ウ":
            return [
                "1. Small vertical dot at the top center.",
                "2. Short vertical stroke on the left.",
                "3. Horizontal line from the top of the second line to the right, then bending down-left."
            ]
        case "エ":
            return [
                "1. Horizontal stroke left-to-right at the top.",
                "2. Vertical line down from the center.",
                "3. Longer horizontal stroke left-to-right at the bottom."
            ]
        case "オ":
            return [
                "1. Horizontal stroke left-to-right.",
                "2. Vertical stroke down, bending left-up at the bottom.",
                "3. Diagonal stroke downwards on the right."
            ]
            
        // --- Katakana Ka Row ---
        case "カ":
            return [
                "1. Horizontal stroke left-to-right, bending down-left with a hook.",
                "2. Diagonal stroke cutting through the first line from left to right."
            ]
        case "キ":
            return [
                "1. Short horizontal line left-to-right.",
                "2. Parallel horizontal line below it.",
                "3. Vertical line cutting through both, ending with a curve to the left."
            ]
        case "ク":
            return [
                "1. Left-downward diagonal stroke.",
                "2. Horizontal line from the top of the first line to the right, bending down-left."
            ]
        case "ケ":
            return [
                "1. Left-downward diagonal stroke.",
                "2. Horizontal line from the middle of the first line to the right.",
                "3. Long curving vertical line cutting through the second stroke."
            ]
        case "コ":
            return [
                "1. Horizontal line left-to-right, bending down.",
                "2. Horizontal line at the bottom connecting to the vertical stroke."
            ]
            
        // --- Katakana Sa Row ---
        case "サ":
            return [
                "1. Horizontal stroke left-to-right.",
                "2. Vertical stroke down-right on the left.",
                "3. Longer vertical stroke down-left on the right."
            ]
        case "シ":
            return [
                "1. Small diagonal dot at the top-left.",
                "2. Another parallel diagonal dot below it.",
                "3. Upward sweeping stroke starting from the bottom-left."
            ]
        case "ス":
            return [
                "1. Horizontal stroke left-to-right, bending down-left.",
                "2. Diagonal stroke extending down-right from the vertical bend."
            ]
        case "セ":
            return [
                "1. Horizontal line left-to-right, bending down.",
                "2. Vertical line curving up-right cutting through the top stroke."
            ]
        case "ソ":
            return [
                "1. Short diagonal dot at the top-left.",
                "2. Downward sweeping stroke starting from the top-right."
            ]
            
        default:
            return nil
        }
    }
}
