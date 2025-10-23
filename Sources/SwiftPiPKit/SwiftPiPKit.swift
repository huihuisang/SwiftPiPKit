import SwiftUI

/// SwiftPiPKit - A modern Swift package for Picture-in-Picture in SwiftUI
///
/// SwiftPiPKit provides a simple and type-safe way to implement Picture-in-Picture (PiP)
/// functionality in your SwiftUI applications. It supports displaying any custom SwiftUI View
/// in a PiP window, with full control over lifecycle and navigation.
///
/// ## Features
/// - Generic support for any SwiftUI View
/// - Seamless state synchronization between main app and PiP window
/// - Navigation restoration support
/// - iOS 15+ with ContentSource API
///
/// ## Basic Usage
///
/// 1. Create a PiPManager with your custom content:
/// ```swift
/// @StateObject private var pipManager = PiPManager {
///     MyCustomPiPView()
/// }
/// ```
///
/// 2. Attach an anchor view (must be visible on screen):
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
///
/// 3. Control PiP lifecycle:
/// ```swift
/// pipManager.startPictureInPicture()
/// pipManager.stopPictureInPicture()
/// ```
///
/// ## Requirements
/// - iOS 15.0+
/// - Add `UIBackgroundModes` with `audio` to your Info.plist
///
/// ## Testing
/// - **Real device required**: PiP functionality requires `AVPictureInPictureController` which is only available on physical devices
/// - Xcode Previews and Simulators do not support Picture-in-Picture
/// - For development, test on actual iPhone or iPad hardware
///
/// ## See Also
/// - ``PiPManager``
/// - ``PiPAnchorView``

