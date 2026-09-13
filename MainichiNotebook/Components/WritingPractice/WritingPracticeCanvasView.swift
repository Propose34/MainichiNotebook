import SwiftUI
import PencilKit

enum WritingPracticeTool: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case pencil = "Pencil"
    case eraser = "Eraser"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .pen: return "pencil.tip"
        case .pencil: return "pencil"
        case .eraser: return "eraser.fill"
        }
    }
    
    var labelTh: String {
        switch self {
        case .pen: return "ปากกา"
        case .pencil: return "ดินสอ"
        case .eraser: return "ยางลบ"
        }
    }
}

class WritingPracticeCanvasController: ObservableObject {
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    weak var canvasView: PKCanvasView?
    
    func undo() {
        guard let um = canvasView?.undoManager, um.canUndo else { return }
        um.undo()
        updateUndoState()
    }
    
    func redo() {
        guard let um = canvasView?.undoManager, um.canRedo else { return }
        um.redo()
        updateUndoState()
    }
    
    func clear() {
        canvasView?.drawing = PKDrawing()
        updateUndoState()
    }
    
    func updateUndoState() {
        let um = canvasView?.undoManager
        canUndo = um?.canUndo ?? false
        canRedo = um?.canRedo ?? false
    }
}

struct WritingPracticeCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var toolType: WritingPracticeTool
    var strokeWidth: CGFloat
    var strokeColor: Color
    @ObservedObject var controller: WritingPracticeCanvasController
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: WritingPracticeCanvasView
        
        init(_ parent: WritingPracticeCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            if canvasView.drawing != parent.drawing {
                parent.drawing = canvasView.drawing
            }
            parent.controller.updateUndoState()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput // Support both Apple Pencil and finger drawing
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        canvas.delegate = context.coordinator
        
        controller.canvasView = canvas
        applyTool(to: canvas)
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        
        applyTool(to: uiView)
        
        if controller.canvasView !== uiView {
            controller.canvasView = uiView
            controller.updateUndoState()
        }
    }
    
    private func applyTool(to canvas: PKCanvasView) {
        let uiColor = UIColor(strokeColor)
        switch toolType {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: uiColor, width: strokeWidth)
        case .pencil:
            canvas.tool = PKInkingTool(.pencil, color: uiColor, width: strokeWidth)
        case .eraser:
            canvas.tool = PKEraserTool(.vector)
        }
    }
}
