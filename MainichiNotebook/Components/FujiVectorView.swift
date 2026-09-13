import SwiftUI

struct FujiVectorView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Soft gradient sky background fading into paper cream
                LinearGradient(
                    colors: [AppTheme.paperBeige.opacity(0.4), AppTheme.paperBackground.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Rising Sun
                Circle()
                    .fill(AppTheme.sakuraPink.opacity(0.45))
                    .frame(width: h * 0.7, height: h * 0.7)
                    .position(x: w * 0.75, y: h * 0.4)
                
                // Birds flying in distance
                Path { path in
                    // Bird 1
                    path.move(to: CGPoint(x: w * 0.25, y: h * 0.25))
                    path.addQuadCurve(to: CGPoint(x: w * 0.27, y: h * 0.24), control: CGPoint(x: w * 0.26, y: h * 0.21))
                    path.addQuadCurve(to: CGPoint(x: w * 0.29, y: h * 0.25), control: CGPoint(x: w * 0.28, y: h * 0.21))
                    
                    // Bird 2 (smaller)
                    path.move(to: CGPoint(x: w * 0.31, y: h * 0.29))
                    path.addQuadCurve(to: CGPoint(x: w * 0.325, y: h * 0.28), control: CGPoint(x: w * 0.318, y: h * 0.25))
                    path.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.29), control: CGPoint(x: w * 0.333, y: h * 0.25))
                    
                    // Bird 3 (tiny)
                    path.move(to: CGPoint(x: w * 0.21, y: h * 0.32))
                    path.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.315), control: CGPoint(x: w * 0.215, y: h * 0.295))
                    path.addQuadCurve(to: CGPoint(x: w * 0.23, y: h * 0.32), control: CGPoint(x: w * 0.225, y: h * 0.295))
                }
                .stroke(AppTheme.textMuted.opacity(0.4), lineWidth: 1.5)
                
                // Mt. Fuji Mountain Base
                Path { path in
                    path.move(to: CGPoint(x: w * 0.45, y: h)) // Left foot
                    // Curve up to left shoulder of peak
                    path.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.45), control: CGPoint(x: w * 0.55, y: h * 0.75))
                    // Flat top peak
                    path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.45))
                    // Curve down to right foot
                    path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h), control: CGPoint(x: w * 0.75, y: h * 0.75))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "788D9C"), Color(hex: "A3BFCF").opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Snow Cap
                Path { path in
                    path.move(to: CGPoint(x: w * 0.62, y: h * 0.45))
                    path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.45))
                    
                    // Right snow line going down
                    path.addQuadCurve(to: CGPoint(x: w * 0.705, y: h * 0.57), control: CGPoint(x: w * 0.695, y: h * 0.51))
                    
                    // Jagged snow boundary line
                    path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.54))
                    path.addLine(to: CGPoint(x: w * 0.67, y: h * 0.59))
                    path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.55))
                    path.addLine(to: CGPoint(x: w * 0.635, y: h * 0.61))
                    path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.54))
                    path.addLine(to: CGPoint(x: w * 0.61, y: h * 0.56))
                    
                    // Left snow line going up
                    path.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.45), control: CGPoint(x: w * 0.615, y: h * 0.505))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.95))
                
                // Cherry Blossom branch silhouette on the left/bottom
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.6))
                    path.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.55), control: CGPoint(x: w * 0.08, y: h * 0.56))
                    
                    // Tiny branches
                    path.move(to: CGPoint(x: w * 0.08, y: h * 0.57))
                    path.addLine(to: CGPoint(x: w * 0.11, y: h * 0.52))
                    
                    path.move(to: CGPoint(x: w * 0.04, y: h * 0.58))
                    path.addLine(to: CGPoint(x: w * 0.06, y: h * 0.53))
                }
                .stroke(AppTheme.textDark.opacity(0.3), lineWidth: 2)
                
                // Cherry Blossom flowers
                Group {
                    // Small flower shapes
                    CherryBlossomFlower(size: 14)
                        .position(x: w * 0.15, y: h * 0.55)
                    CherryBlossomFlower(size: 12)
                        .position(x: w * 0.11, y: h * 0.51)
                    CherryBlossomFlower(size: 10)
                        .position(x: w * 0.06, y: h * 0.525)
                    CherryBlossomFlower(size: 8)
                        .position(x: w * 0.08, y: h * 0.55)
                }
            }
        }
        .clipped()
    }
}

struct CherryBlossomFlower: View {
    var size: CGFloat
    
    var body: some View {
        ZStack {
            // 5 Petals
            ForEach(0..<5) { index in
                Circle()
                    .fill(AppTheme.sakuraPink)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
            
            // Center yellow dot
            Circle()
                .fill(Color(hex: "FCE4A6"))
                .frame(width: size * 0.2, height: size * 0.2)
        }
    }
}
