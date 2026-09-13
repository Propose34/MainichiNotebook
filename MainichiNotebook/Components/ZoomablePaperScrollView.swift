import SwiftUI
import UIKit

class CenteringUIScrollView: UIScrollView {
    var zoomContentView: UIView?

    func updateContentInsetForCentering() {
        guard zoomContentView != nil else { return }
        
        let boundsSize = bounds.size
        let contentSize = contentSize
        
        // Calculate the padding needed to center the content view inside the scroll view bounds
        let horizontalPadding = boundsSize.width > contentSize.width ? (boundsSize.width - contentSize.width) * 0.5 : 0.0
        let verticalPadding = boundsSize.height > contentSize.height ? (boundsSize.height - contentSize.height) * 0.5 : 0.0
        
        // Update content insets to center content view when smaller than screen viewport
        let insets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        
        if self.contentInset != insets {
            self.contentInset = insets
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateContentInsetForCentering()
    }
}

struct ZoomablePaperScrollView<Content: View>: UIViewRepresentable {
    let pageId: UUID
    @Binding var fitTrigger: UUID
    let contentWidth: CGFloat
    let contentHeight: CGFloat
    let content: Content

    init(pageId: UUID, fitTrigger: Binding<UUID>, width: CGFloat, height: CGFloat, @ViewBuilder content: () -> Content) {
        self.pageId = pageId
        self._fitTrigger = fitTrigger
        self.contentWidth = width
        self.contentHeight = height
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> CenteringUIScrollView {
        let scrollView = CenteringUIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        
        // Manual frame allocation prevents AutoLayout conflicts during zooming
        hostingController.view.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.addSubview(hostingController.view)
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        scrollView.zoomContentView = hostingController.view
        context.coordinator.hostingController = hostingController
        
        return scrollView
    }

    func updateUIView(_ uiView: CenteringUIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        
        let viewportSize = uiView.bounds.size
        let pageChanged = context.coordinator.currentPageId != pageId
        let viewportChanged = abs(context.coordinator.lastViewportSize.width - viewportSize.width) > 5 ||
                              abs(context.coordinator.lastViewportSize.height - viewportSize.height) > 5
        let fitRequested = context.coordinator.lastFitTrigger != fitTrigger
        
        if pageChanged || fitRequested || (viewportChanged && viewportSize.width > 0) {
            context.coordinator.currentPageId = pageId
            context.coordinator.lastViewportSize = viewportSize
            context.coordinator.lastFitTrigger = fitTrigger
            
            // Perform fit-to-screen scaling calculation
            let widthScale = viewportSize.width / contentWidth
            let heightScale = viewportSize.height / contentHeight
            let fitScale = min(widthScale, heightScale)
            
            uiView.minimumZoomScale = min(0.3, fitScale * 0.8)
            uiView.maximumZoomScale = 4.0
            
            // Set zoomScale inside a smooth UIView animation block
            UIView.animate(withDuration: pageChanged ? 0.0 : 0.3) {
                uiView.zoomScale = fitScale
                uiView.updateContentInsetForCentering()
            }
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var hostingController: UIHostingController<Content>?
        var currentPageId: UUID?
        var lastViewportSize: CGSize = .zero
        var lastFitTrigger: UUID = UUID()

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return (scrollView as? CenteringUIScrollView)?.zoomContentView
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            if let centeringScrollView = scrollView as? CenteringUIScrollView {
                centeringScrollView.updateContentInsetForCentering()
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Recognize parent pinch/pan gestures simultaneously with child gestures
            return true
        }
    }
}
