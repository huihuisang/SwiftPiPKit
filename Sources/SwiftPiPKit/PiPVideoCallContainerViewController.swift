import AVKit
import UIKit

/// Internal container view controller that wraps embedded content for PiP display
///
/// This class conforms to AVPictureInPictureVideoCallViewController requirements
/// and embeds a UIHostingController containing the SwiftUI content.
final class PiPVideoCallContainerViewController: AVPictureInPictureVideoCallViewController {
    
    private let embeddedController: UIViewController
    
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
        
        // Embed the content view controller
        addChild(embeddedController)
        embeddedController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(embeddedController.view)
        
        // Pin to all edges
        NSLayoutConstraint.activate([
            embeddedController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            embeddedController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            embeddedController.view.topAnchor.constraint(equalTo: view.topAnchor),
            embeddedController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        embeddedController.didMove(toParent: self)
    }
}

