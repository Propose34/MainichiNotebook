import SwiftUI

/// Wraps any annotation content view with dragging, resizing, and delete controls.
/// Controls are only active when `isSelectMoveMode` is true (Select/Move tool active).
struct DraggableOverlayWrapper<Content: View>: View {
    @Binding var item: AnnotationItem
    let isSelectMoveMode: Bool      // Previously named isEditingEnabled
    let onDelete: () -> Void
    var onDragEnded: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var resizeOffset: CGSize = .zero

    var body: some View {
        let dragGesture = DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($dragOffset) { value, state, _ in
                guard isSelectMoveMode else { return }
                state = value.translation
            }
            .onEnded { value in
                guard isSelectMoveMode else { return }
                item.xOffset += Double(value.translation.width)
                item.yOffset += Double(value.translation.height)
                onDragEnded?()
            }

        let resizeGesture = DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($resizeOffset) { value, state, _ in
                guard isSelectMoveMode else { return }
                state = value.translation
            }
            .onEnded { value in
                guard isSelectMoveMode else { return }
                item.width  = max(50.0, item.width  + Double(value.translation.width))
                item.height = max(50.0, item.height + Double(value.translation.height))
                onDragEnded?()
            }

        let liveWidth  = max(50.0, item.width  + (isSelectMoveMode ? Double(resizeOffset.width)  : 0))
        let liveHeight = max(50.0, item.height + (isSelectMoveMode ? Double(resizeOffset.height) : 0))
        let liveX      = item.xOffset + (isSelectMoveMode ? Double(dragOffset.width)  : 0)
        let liveY      = item.yOffset + (isSelectMoveMode ? Double(dragOffset.height) : 0)

        ZStack {
            // Content frame
            content()
                .frame(width: CGFloat(liveWidth), height: CGFloat(liveHeight))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelectMoveMode ? AppTheme.sakuraPink : Color.clear,
                            style: StrokeStyle(lineWidth: 1.5, dash: isSelectMoveMode ? [5, 3] : [])
                        )
                )

            if isSelectMoveMode {
                // Delete button — top-leading corner
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white))
                }
                .position(x: 0, y: 0)
                .buttonStyle(PlainButtonStyle())

                // Resize handle — bottom-trailing corner
                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Circle().fill(AppTheme.sakuraPink))
                    .position(x: CGFloat(liveWidth), y: CGFloat(liveHeight))
                    .gesture(resizeGesture)
            }
        }
        .frame(width: CGFloat(liveWidth), height: CGFloat(liveHeight))
        .gesture(isSelectMoveMode ? dragGesture : nil)
        .offset(x: CGFloat(liveX), y: CGFloat(liveY))
    }
}
