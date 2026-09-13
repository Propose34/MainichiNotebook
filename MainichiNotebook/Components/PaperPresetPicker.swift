import SwiftUI

/// A compact scrollable strip of paper preset buttons shown in the editor top toolbar.
/// Notifies the parent via `onSelect` so the parent can update the current page's preset.
struct PaperPresetPicker: View {
    let currentPreset: PaperPreset
    let onSelect: (PaperPreset) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(PaperPreset.allCases) { preset in
                    Button(action: { onSelect(preset) }) {
                        HStack(spacing: 4) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 11))
                            Text(preset.displayName)
                                .font(AppTheme.fontRounded(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(currentPreset == preset
                                      ? AppTheme.sakuraPinkLight
                                      : AppTheme.paperCard)
                        )
                        .foregroundColor(currentPreset == preset
                                         ? AppTheme.sakuraPink
                                         : AppTheme.textMuted)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(currentPreset == preset
                                        ? AppTheme.sakuraPink
                                        : AppTheme.borderLight,
                                        lineWidth: currentPreset == preset ? 1.2 : 0.7)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}
