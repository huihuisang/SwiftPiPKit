import AVKit
import UIKit

/// Internal container view controller that wraps embedded content for PiP display
///
/// This class conforms to AVPictureInPictureVideoCallViewController requirements
/// and embeds a UIHostingController containing the SwiftUI content.
/// Supports dynamic content replacement without recreating the PiP controller.
final class PiPVideoCallContainerViewController: AVPictureInPictureVideoCallViewController {
    private var embeddedController: UIViewController
    
    /// Creates a new container with an embedded view controller
    ///
    /// - Parameter embedded: The view controller to embed (typically a UIHostingController)
    init(embedded: UIViewController) {
        self.embeddedController = embedded
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        embedViewController(embeddedController)
    }
    
    /// Replaces the current embedded content with a new view controller
    ///
    /// This allows dynamic content switching while PiP is active.
    /// The transition is seamless without interrupting the PiP session.
    ///
    /// - Parameter newController: The new view controller to embed
    func replaceContent(with newController: UIViewController) {
        // Remove old controller
        embeddedController.willMove(toParent: nil)
        embeddedController.view.removeFromSuperview()
        embeddedController.removeFromParent()
        
        // Embed new controller
        embeddedController = newController
        
        // Only embed if view is loaded
        if isViewLoaded {
            embedViewController(newController)
        }
    }
    
    // MARK: - Private Methods
    
    private func embedViewController(_ controller: UIViewController) {
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        view.addSubview(controller.view)
        
        // Pin to all edges
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        controller.didMove(toParent: self)
    }
}
