import SwiftUI

struct PracticeGridPaperView: View {
    var body: some View {
        ZStack {
            // Cozy cream card board with subtle stroke
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.paperCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.borderLight, lineWidth: 1.5)
                )
            
            // Traditional Gojuon worksheet quadrant crosshairs
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    // Vertical dashed guidline
                    path.move(to: CGPoint(x: w / 2, y: 0))
                    path.addLine(to: CGPoint(x: w / 2, y: h))
                    
                    // Horizontal dashed guideline
                    path.move(to: CGPoint(x: 0, y: h / 2))
                    path.addLine(to: CGPoint(x: w, y: h / 2))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [5, 5]))
                .foregroundColor(AppTheme.sakuraPink.opacity(0.3))
            }
        }
    }
}
