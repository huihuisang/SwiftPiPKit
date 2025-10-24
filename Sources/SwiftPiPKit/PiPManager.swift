import AVFoundation
import AVKit
import SwiftUI
import UIKit

/// Generic Picture-in-Picture Manager for SwiftUI
///
/// This manager handles the lifecycle of Picture-in-Picture (PiP) mode for custom SwiftUI content.
/// It uses AVPictureInPictureController with ContentSource to display any SwiftUI View in PiP mode.
///
/// Supports flexible content management:
/// - Optional default content at initialization
/// - Dynamic content replacement via updateContent()
/// - Temporary content override when starting PiP
///
/// - Note: Requires iOS 15+ and proper Info.plist configuration (UIBackgroundModes: audio)
public class PiPManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    // MARK: - Public Properties
    
    /// Indicates whether Picture-in-Picture is currently active
    @Published public var isPictureInPictureActive = false
    
    /// Callback invoked when user requests to restore the app from PiP
    public var onRestoreRequested: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var pipController: AVPictureInPictureController?
    private weak var activeSourceView: UIView?
    private weak var persistentAnchorView: UIView?
    private var automaticallyFromInline: Bool
    private var videoCallController: PiPVideoCallContainerViewController?
    private var contentBuilder: (() -> AnyView)?
    
    // Hold completion to run after destination anchor is ready
    private var pendingRestoreCompletion: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new PiP Manager without default content
    ///
    /// Content must be specified later when calling startPictureInPicture() or updateContent().
    ///
    /// Example:
    /// ```swift
    /// let pipManager = PiPManager()
    /// // Provide content when starting PiP
    /// pipManager.startPictureInPicture { MyView() }
    /// ```
    override public init() {
        self.contentBuilder = nil
        self.automaticallyFromInline = true
        super.init()
        setupAudioSession()
        checkPiPSupport()
    }
    
    public init(automaticallyFromInline: Bool = true) {
        self.contentBuilder = nil
        self.automaticallyFromInline = automaticallyFromInline
        super.init()
        setupAudioSession()
        checkPiPSupport()
    }
    
    /// Creates a new PiP Manager with default content
    ///
    /// - Parameter content: A closure that returns the default SwiftUI View to display in PiP mode
    ///
    /// Example:
    /// ```swift
    /// let pipManager = PiPManager {
    ///     MyCustomPiPView(data: myData)
    /// }
    /// ```
    public init(automaticallyFromInline: Bool = true, @ViewBuilder content: @escaping () -> some View) {
        self.contentBuilder = { AnyView(content()) }
        self.automaticallyFromInline = automaticallyFromInline
        super.init()
        setupAudioSession()
        checkPiPSupport()
    }
    
    // MARK: - Private Setup Methods
    
    private func setupAudioSession() {
        // Optional: Audio session is NOT required for UI-only PiP
        // Keeping it as ambient to avoid unnecessary behavior changes
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
        } catch {
            print("SwiftPiPKit: Audio session setup skipped: \(error)")
        }
    }
    
    private func checkPiPSupport() {
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
    
    /// Start Picture-in-Picture mode with default content
    ///
    /// Call this method to activate PiP mode using the default content.
    /// The anchor view must be attached first using `attachActiveSourceView(_:)`.
    ///
    /// - Parameter preferredContentSize: Optional custom size for the PiP window
    ///
    /// Example:
    /// ```swift
    /// pipManager.startPictureInPicture()
    /// ```
    public func startPictureInPicture(content: (() -> AnyView)? = nil, preferredContentSize: CGSize? = nil) {
        print("SwiftPiPKit: === Try to start Picture in Picture ===")
        
        guard let content = content ?? contentBuilder else {
            print("SwiftPiPKit: ⚠️ No content provided for PiP. Please provide content in init() or startPictureInPicture(content:)")
            return
        }
        
        startPiPInternal(content: content, preferredContentSize: preferredContentSize)
    }
    
    /// Start Picture-in-Picture mode with temporary content
    ///
    /// Call this method to activate PiP mode with custom content that overrides the default.
    /// The anchor view must be attached first using `attachActiveSourceView(_:)`.
    ///
    /// - Parameters:
    ///   - preferredContentSize: Optional custom size for the PiP window
    ///   - content: Temporary content to display, overrides the default content for this session
    ///
    /// Example:
    /// ```swift
    /// pipManager.startPictureInPicture {
    ///     TemporaryPiPView()
    /// }
    /// ```
    public func startPictureInPicture(
        preferredContentSize: CGSize? = nil,
        @ViewBuilder content: @escaping () -> some View
    ) {
        print("SwiftPiPKit: === Try to start Picture in Picture ===")
        let tempContent: () -> AnyView = { AnyView(content()) }
        startPiPInternal(content: tempContent, preferredContentSize: preferredContentSize)
    }
    
    // MARK: - Private Start PiP Implementation
    
    private func startPiPInternal(content: @escaping () -> AnyView, preferredContentSize: CGSize?) {
        // Update content if controller already exists
        if let videoVC = videoCallController {
            let newHost = UIHostingController(rootView: content())
            videoVC.replaceContent(with: newHost)
            if let preferredContentSize {
                videoVC.preferredContentSize = preferredContentSize
            }
        }
        
        guard let pip = pipController else {
            print("SwiftPiPKit: ⚠️ PiP controller not ready (anchor not attached yet?)")
            return
        }
        
        print("SwiftPiPKit: isPictureInPicturePossible: \(pip.isPictureInPicturePossible)")
        print("SwiftPiPKit: isPictureInPictureSuspended: \(pip.isPictureInPictureSuspended)")
        
        if let preferredContentSize {
            videoCallController?.preferredContentSize = preferredContentSize
        }
        
        if pip.isPictureInPicturePossible {
            pip.startPictureInPicture()
            print("SwiftPiPKit: 🎬 Starting PiP...")
        } else {
            // Retry shortly after layout/visibility settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startPiPInternal(content: content, preferredContentSize: preferredContentSize)
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
    
    /// Update the default content displayed in PiP mode
    ///
    /// This method permanently updates the default content. If PiP is currently active,
    /// the content will be updated immediately without interrupting the PiP session.
    ///
    /// - Parameter content: A closure that returns the new SwiftUI View to display
    ///
    /// Example:
    /// ```swift
    /// pipManager.updateContent {
    ///     NewPiPView(updatedData: data)
    /// }
    /// ```
    public func updateContent(@ViewBuilder content: @escaping () -> some View) {
        contentBuilder = { AnyView(content()) }
        
        // If PiP is active, update the content immediately
        if isPictureInPictureActive, let videoVC = videoCallController {
            let newHost = UIHostingController(rootView: AnyView(content()))
            videoVC.replaceContent(with: newHost)
            print("SwiftPiPKit: Content updated while PiP is active")
        }
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
            // Use default content if available, otherwise create a placeholder
            let initialContent = contentBuilder?() ?? AnyView(EmptyView())
            
            let host = UIHostingController(rootView: initialContent)
            let videoVC = PiPVideoCallContainerViewController(embedded: host)
            videoVC.preferredContentSize = host.view.intrinsicContentSize
            self.videoCallController = videoVC
            
            let contentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: sourceView,
                contentViewController: videoVC
            )
            
            let controller = AVPictureInPictureController(contentSource: contentSource)
            controller.delegate = self
            controller.canStartPictureInPictureAutomaticallyFromInline = automaticallyFromInline
            
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
