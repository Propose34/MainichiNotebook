import Foundation
import PencilKit

/// Shared ObservableObject that holds a weak reference to the PKCanvasView so the
/// SwiftUI layer can trigger undo/redo and observe their availability without
/// going through fragile NotificationCenter posts.
class PencilCanvasController: ObservableObject {
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    weak var canvasView: PKCanvasView?

    // MARK: - Actions

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

    // MARK: - State sync (called by the canvas delegate after any drawing change)

    func updateUndoState() {
        let um = canvasView?.undoManager
        canUndo = um?.canUndo ?? false
        canRedo = um?.canRedo ?? false
    }
}
