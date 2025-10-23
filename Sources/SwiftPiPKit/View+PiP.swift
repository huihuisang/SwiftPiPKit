import SwiftUI

public extension View {
    /// Attach this view to a PiP Manager for Picture-in-Picture functionality
    ///
    /// This is a convenience method that simplifies PiP integration by handling
    /// the anchor view setup automatically.
    ///
    /// - Parameters:
    ///   - manager: The PiPManager instance to attach to
    ///   - size: Optional custom size for the anchor view.
    ///           If nil (default), the anchor view will match the parent view's size.
    ///           Pass CGSize(width: 1, height: 1) for a minimal footprint.
    ///   - configure: Optional configuration closure for advanced UIView customization
    ///
    /// - Returns: A view with PiP anchor attached
    ///
    /// Example usage:
    /// ```swift
    /// // Simple usage with default container size
    /// Button("Start PiP") {
    ///     pipManager.startPictureInPicture()
    /// }
    /// .attachToPiP(pipManager)
    ///
    /// // Custom size (minimal footprint)
    /// Button("Start PiP") {
    ///     pipManager.startPictureInPicture()
    /// }
    /// .attachToPiP(pipManager, size: CGSize(width: 1, height: 1))
    ///
    /// // Advanced configuration
    /// Button("Start PiP") {
    ///     pipManager.startPictureInPicture()
    /// }
    /// .attachToPiP(pipManager) { view in
    ///     view.backgroundColor = .clear
    /// }
    /// ```
    func attachToPiP(
        _ manager: PiPManager,
        size: CGSize? = nil,
        configure: ((UIView) -> Void)? = nil
    ) -> some View {
        self.background {
            if let size = size {
                PiPAnchorView { view in
                    configure?(view)
                    manager.attachActiveSourceView(view)
                }
                .frame(width: size.width, height: size.height)
                .background(Color.clear)
                .accessibilityHidden(true)
            } else {
                PiPAnchorView { view in
                    configure?(view)
                    manager.attachActiveSourceView(view)
                }
                .background(Color.clear)
                .accessibilityHidden(true)
            }
        }
    }
    
    /// Update the PiP anchor point for restore animation
    ///
    /// Call this method on the destination view when navigating to a new screen
    /// where you want the PiP window to animate back to. This is typically used
    /// in conjunction with `PiPManager.onRestoreRequested`.
    ///
    /// - Parameters:
    ///   - manager: The PiPManager instance to update
    ///   - size: Optional custom size for the anchor view.
    ///           If nil (default), the anchor view will match the parent view's size.
    ///           Pass a custom CGSize for specific dimensions.
    ///   - configure: Optional configuration closure for advanced UIView customization
    ///
    /// - Returns: A view with PiP restore anchor attached
    ///
    /// Example usage:
    /// ```swift
    /// // In the main view, set up restore callback
    /// pipManager.onRestoreRequested = {
    ///     navigateToDetailView = true
    /// }
    ///
    /// // In the destination view, update anchor
    /// DetailView()
    ///     .updatePiPAnchor(pipManager)
    ///
    /// // Custom size
    /// DetailView()
    ///     .updatePiPAnchor(pipManager, size: CGSize(width: 2, height: 2))
    /// ```
    func updatePiPAnchor(
        _ manager: PiPManager,
        size: CGSize? = nil,
        configure: ((UIView) -> Void)? = nil
    ) -> some View {
        self.background {
            if let size = size {
                PiPAnchorView { view in
                    configure?(view)
                    manager.updateAnchorForRestore(view)
                }
                .frame(width: size.width, height: size.height)
                .background(Color.clear)
                .accessibilityHidden(true)
            } else {
                PiPAnchorView { view in
                    configure?(view)
                    manager.updateAnchorForRestore(view)
                }
                .background(Color.clear)
                .accessibilityHidden(true)
            }
        }
    }
}
