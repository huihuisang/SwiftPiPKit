import AVFoundation
import AVKit
import SwiftUI
import UIKit

/// Generic Picture-in-Picture Manager for SwiftUI
///
/// This manager handles the lifecycle of Picture-in-Picture (PiP) mode for custom SwiftUI content.
/// It uses AVPictureInPictureController with ContentSource to display any SwiftUI View in PiP mode.
///
/// - Note: Requires iOS 15+ and proper Info.plist configuration (UIBackgroundModes: audio)
public class PiPManager<Content: View>: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    
    // MARK: - Public Properties
    
    /// Indicates whether Picture-in-Picture is currently active
    @Published public var isPictureInPictureActive = false
    
    /// Callback invoked when user requests to restore the app from PiP
    public var onRestoreRequested: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var pipController: AVPictureInPictureController?
    private weak var activeSourceView: UIView?
    private weak var persistentAnchorView: UIView?
    private var videoCallController: AVPictureInPictureVideoCallViewController?
    private var contentBuilder: () -> Content
    
    // Hold completion to run after destination anchor is ready
    private var pendingRestoreCompletion: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new PiP Manager with custom content
    ///
    /// - Parameter content: A closure that returns the SwiftUI View to display in PiP mode
    ///
    /// Example:
    /// ```swift
    /// let pipManager = PiPManager {
    ///     MyCustomPiPView(data: myData)
    /// }
    /// ```
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.contentBuilder = content
        super.init()
        
        // Optional: Audio session is NOT required for UI-only PiP
        // Keeping it as ambient to avoid unnecessary behavior changes
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
        } catch {
            print("SwiftPiPKit: Audio session setup skipped: \(error)")
        }
        
        if !AVPictureInPictureController.isPictureInPictureSupported() {
            print("❌ SwiftPiPKit: Picture in Picture is not supported on this device")
        } else {
            print("✅ SwiftPiPKit: Picture in Picture is supported")
        }
    }
    
    // MARK: - Public Methods
    
    /// Attach a visible on-screen anchor view as the PiP source
    ///
    /// This method must be called with a view that is visible on screen to enable PiP.
    /// The view acts as an anchor point for the PiP window animation.
    ///
    /// - Parameter view: A UIView that is currently visible on screen
    public func attachActiveSourceView(_ view: UIView) {
        // Ensure we have a persistent anchor attached to window
        guard let window = view.window else {
            DispatchQueue.main.async { [weak self] in
                self?.attachActiveSourceView(view)
            }
            return
        }
        
        let anchor: UIView
        if let existing = persistentAnchorView {
            anchor = existing
        } else {
            let newAnchor = UIView(frame: .zero)
            newAnchor.isOpaque = false
            newAnchor.isUserInteractionEnabled = false
            window.addSubview(newAnchor)
            persistentAnchorView = newAnchor
            anchor = newAnchor
        }
        
        // Position anchor over the provided view (convert to window coordinates)
        let rect = view.convert(view.bounds, to: window)
        anchor.frame = rect
        activeSourceView = anchor
        
        createPiPControllerIfNeeded()
    }
    
    /// Start Picture-in-Picture mode
    ///
    /// Call this method to activate PiP mode. The anchor view must be attached first
    /// using `attachActiveSourceView(_:)`.
    public func startPictureInPicture() {
        print("SwiftPiPKit: === Try to start Picture in Picture ===")
        
        guard let pip = pipController else {
            print("SwiftPiPKit: ⚠️ PiP controller not ready (anchor not attached yet?)")
            return
        }
        
        print("SwiftPiPKit: isPictureInPicturePossible: \(pip.isPictureInPicturePossible)")
        print("SwiftPiPKit: isPictureInPictureSuspended: \(pip.isPictureInPictureSuspended)")
        
        if pip.isPictureInPicturePossible {
            pip.startPictureInPicture()
            print("SwiftPiPKit: 🎬 Starting PiP...")
        } else {
            // Retry shortly after layout/visibility settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startPictureInPicture()
            }
        }
    }
    
    /// Stop Picture-in-Picture mode
    ///
    /// Call this method to deactivate PiP mode and return to normal display.
    public func stopPictureInPicture() {
        // If currently handling restore animation, don't interrupt it
        pipController?.stopPictureInPicture()
    }
    
    /// Update the anchor point for PiP restore animation
    ///
    /// Call this when navigating to a new screen where you want the PiP window
    /// to animate back to. This is typically used in conjunction with `onRestoreRequested`.
    ///
    /// - Parameter newAnchor: The new UIView to use as the restore anchor point
    public func updateAnchorForRestore(_ newAnchor: UIView) {
        guard let completion = pendingRestoreCompletion else { return }
        
        // Move the persistent anchor to overlap the new target view, keeping same PiP controller instance
        if let window = newAnchor.window {
            if persistentAnchorView == nil {
                let anchor = UIView(frame: .zero)
                anchor.isOpaque = false
                anchor.isUserInteractionEnabled = false
                window.addSubview(anchor)
                persistentAnchorView = anchor
            }
            if let anchor = persistentAnchorView {
                let rect = newAnchor.convert(newAnchor.bounds, to: window)
                anchor.frame = rect
                activeSourceView = anchor
            }
        }
        
        completion(true)
        pendingRestoreCompletion = nil
    }
    
    // MARK: - Private Methods
    
    private func createPiPControllerIfNeeded() {
        guard pipController == nil, let sourceView = activeSourceView else { return }
        
        if #available(iOS 15.0, *) {
            let host = UIHostingController(rootView: contentBuilder())
            let videoVC = PiPVideoCallContainerViewController(embedded: host)
            self.videoCallController = videoVC
            
            let contentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: sourceView,
                contentViewController: videoVC
            )
            
            let controller = AVPictureInPictureController(contentSource: contentSource)
            controller.delegate = self
            controller.canStartPictureInPictureAutomaticallyFromInline = true
            
            pipController = controller
            print("SwiftPiPKit: ✅ PiP controller created with ContentSource")
        } else {
            print("SwiftPiPKit: ❌ iOS 15+ is required for ContentSource-based PiP")
        }
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isPictureInPictureActive = true
        }
        print("SwiftPiPKit: Picture in Picture will start")
    }
    
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("SwiftPiPKit: Picture in Picture did start")
    }
    
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("SwiftPiPKit: Picture in Picture will stop")
    }
    
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isPictureInPictureActive = false
        }
        print("SwiftPiPKit: Picture in Picture did stop")
    }
    
    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        // then complete when new anchor is ready
        print("SwiftPiPKit: User requested restore from PiP")
        pendingRestoreCompletion = completionHandler
        onRestoreRequested?()
    }
    
    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        print("SwiftPiPKit: Failed to start Picture in Picture: \(error.localizedDescription)")
    }
}

