import SwiftUI

struct StrokeOrderVisualGuideView: View {
    let character: String
    var size: CGFloat = 140
    
    var body: some View {
        ZStack {
            // Cozy cream card board with subtle stroke
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.paperCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.borderLight, lineWidth: 1.5)
                )
            
            // Faint quadrant background lines (Genkou Youshi quadrant guides)
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: w / 2, y: 0))
                    path.addLine(to: CGPoint(x: w / 2, y: h))
                    path.move(to: CGPoint(x: 0, y: h / 2))
                    path.addLine(to: CGPoint(x: w, y: h / 2))
                }
                .stroke(style: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
                .foregroundColor(AppTheme.sakuraPink.opacity(0.2))
            }
            
            // Large faint base character
            Text(character)
                .font(AppTheme.fontSerif(size: size * 0.75, weight: .thin))
                .foregroundColor(AppTheme.textDark.opacity(0.06))
            
            // Draw visual paths and numbered badges
            if let strokes = StrokePathRepository.paths(for: character) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    ZStack {
                        // 1. Draw all paths (lines and arrowheads)
                        Path { path in
                            for stroke in strokes {
                                guard stroke.points.count >= 2 else { continue }
                                let pts = stroke.points.map { CGPoint(x: $0.x / 100 * w, y: $0.y / 100 * h) }
                                
                                path.move(to: pts[0])
                                for i in 1..<pts.count {
                                    path.addLine(to: pts[i])
                                }
                                
                                // Draw arrowhead at the end of the stroke
                                let last = pts[pts.count - 1]
                                let secondLast = pts[pts.count - 2]
                                let dx = last.x - secondLast.x
                                let dy = last.y - secondLast.y
                                let angle = atan2(dy, dx)
                                
                                let arrowLength: CGFloat = 7
                                let arrowAngle: CGFloat = .pi * 5 / 6
                                
                                let p1 = CGPoint(
                                    x: last.x + cos(angle + arrowAngle) * arrowLength,
                                    y: last.y + sin(angle + arrowAngle) * arrowLength
                                )
                                let p2 = CGPoint(
                                    x: last.x + cos(angle - arrowAngle) * arrowLength,
                                    y: last.y + sin(angle - arrowAngle) * arrowLength
                                )
                                
                                path.move(to: last)
                                path.addLine(to: p1)
                                path.move(to: last)
                                path.addLine(to: p2)
                            }
                        }
                        .stroke(AppTheme.sakuraPink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round, dash: [4, 2]))
                        
                        // 2. Draw numbered circle badges at the starting points
                        ForEach(0..<strokes.count, id: \.self) { idx in
                            let stroke = strokes[idx]
                            if let firstPt = stroke.points.first {
                                let px = firstPt.x / 100 * w
                                let py = firstPt.y / 100 * h
                                
                                Text("\(idx + 1)")
                                    .font(AppTheme.fontRounded(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 14, height: 14)
                                    .background(AppTheme.darkNavy)
                                    .clipShape(Circle())
                                    .position(x: px, y: py)
                            }
                        }
                    }
                }
            } else {
                // Fallback indicator if no vector coordinates exist (e.g. Kanji)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No Stroke Data")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted.opacity(0.5))
                            .padding(4)
                            .background(AppTheme.paperBeige)
                            .cornerRadius(4)
                    }
                    .padding(6)
                }
            }
        }
        .frame(width: size, height: size)
    }
}
