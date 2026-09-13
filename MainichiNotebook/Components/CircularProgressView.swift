import SwiftUI

struct CircularProgressView: View {
    var progress: Double // 0.0 to 1.0
    var thickness: CGFloat = 8
    var activeColor: Color = AppTheme.darkNavy
    var inactiveColor: Color = AppTheme.paperBeige
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(inactiveColor, lineWidth: thickness)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(activeColor, style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut(duration: 0.8), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(AppTheme.fontRounded(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textDark)
        }
    }
}
