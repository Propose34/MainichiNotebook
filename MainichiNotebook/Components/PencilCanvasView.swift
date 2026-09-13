import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var toolState: DrawingToolState
    var controller: PencilCanvasController   // Weak-holds the canvas for undo/redo

    // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView

        init(_ parent: PencilCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Propagate drawing changes back to SwiftUI binding
            if canvasView.drawing != parent.drawing {
                parent.drawing = canvasView.drawing
            }
            // Refresh undo/redo availability after every stroke change
            parent.controller.updateUndoState()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput   // Supports fingers, passive stylus, Apple Pencil
        canvas.isOpaque = false
        canvas.backgroundColor = .clear   // Grid/paper background shows through
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false

        // Register canvas with controller so undo/redo works
        controller.canvasView = canvas

        applyTool(to: canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Sync drawing data (e.g. after page switch)
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }

        // Always re-apply the current tool so width/color/preset changes take effect
        applyTool(to: uiView)

        // Keep controller reference fresh (view may be recycled)
        if controller.canvasView !== uiView {
            controller.canvasView = uiView
            controller.updateUndoState()
        }
    }

    // MARK: - Tool Application

    private func applyTool(to canvas: PKCanvasView) {
        let color = Color(hex: toolState.colorHex).uiColor
        let width = toolState.strokeWidth

        switch toolState.tool {
        case .pen:
            let inkType: PKInkingTool.InkType
            switch toolState.activePenType {
            case .ballpoint:
                inkType = .pen
            case .fountain:
                inkType = .fountainPen
            case .brush:
                inkType = .watercolor
            case .smoothStudy:
                inkType = .monoline
            }
            canvas.tool = PKInkingTool(inkType, color: color.withAlphaComponent(toolState.opacity), width: width)

        case .pencil:
            canvas.tool = PKInkingTool(.pencil, color: color.withAlphaComponent(toolState.opacity), width: width)

        case .highlighter:
            // Marker type with semi-transparency; scale width for a broad stroke feel
            canvas.tool = PKInkingTool(.marker, color: color.withAlphaComponent(toolState.opacity * 0.4), width: max(width * 2.5, 12.0))

        case .eraser:
            canvas.tool = PKEraserTool(.vector)

        case .selectMove:
            // Hit-testing on this canvas is disabled externally when selectMove is active.
            // Keep a valid tool set so PencilKit doesn't crash if a stroke somehow lands.
            canvas.tool = PKInkingTool(.pen, color: color, width: width)
        }
    }
}

// MARK: - Color Helper (defined here once for the drawing stack)

extension Color {
    var uiColor: UIColor { UIColor(self) }
}
