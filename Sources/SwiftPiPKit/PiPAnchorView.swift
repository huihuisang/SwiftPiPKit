import SwiftUI
import UIKit

/// A lightweight UIView wrapper that serves as an anchor point for Picture-in-Picture
///
/// This view must be visible on screen (within the view hierarchy) for PiP to activate.
/// It can be placed anywhere in your SwiftUI view hierarchy as an overlay or background.
///
/// Example usage:
/// ```swift
/// Button("Start PiP") {
///     pipManager.startPictureInPicture()
/// }
/// .background {
///     PiPAnchorView { view in
///         pipManager.attachActiveSourceView(view)
///     }
///     .frame(width: 1, height: 1)
/// }
/// ```
public struct PiPAnchorView: UIViewRepresentable {
    public typealias UIViewType = UIView
    
    /// Callback invoked when the UIView is ready
    public let onViewReady: (UIView) -> Void
    
    /// Whether the anchor view should be interactive (default: false)
    public var isInteractive: Bool = false
    
    /// Creates a new PiP anchor view
    ///
    /// - Parameters:
    ///   - isInteractive: Whether the view should receive touch events
    ///   - onViewReady: Callback invoked with the UIView when it's ready
    public init(isInteractive: Bool = false, onViewReady: @escaping (UIView) -> Void) {
        self.isInteractive = isInteractive
        self.onViewReady = onViewReady
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        // The view must be on-screen to enable PiP; keep it lightweight
        view.isOpaque = false
        view.isUserInteractionEnabled = isInteractive
        DispatchQueue.main.async {
            onViewReady(view)
        }
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}

