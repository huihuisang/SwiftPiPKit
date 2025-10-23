import XCTest
import SwiftUI
@testable import SwiftPiPKit

/// Basic test suite for SwiftPiPKit
final class SwiftPiPKitTests: XCTestCase {
    
    /// Test that PiPManager can be initialized with custom content
    func testPiPManagerInitialization() throws {
        let manager = PiPManager {
            Text("Test Content")
        }
        
        XCTAssertNotNil(manager, "PiPManager should be initialized")
        XCTAssertFalse(manager.isPictureInPictureActive, "PiP should not be active initially")
        XCTAssertFalse(manager.isRestoringFromPiP, "PiP should not be restoring initially")
    }
    
    /// Test that PiPManager can be initialized with complex view
    func testPiPManagerWithComplexView() throws {
        struct ComplexView: View {
            let counter: Int
            var body: some View {
                VStack {
                    Text("Counter: \(counter)")
                    Button("Action") {}
                }
            }
        }
        
        let manager = PiPManager {
            ComplexView(counter: 42)
        }
        
        XCTAssertNotNil(manager, "PiPManager should handle complex views")
    }
    
    /// Test that restore callback can be set
    func testRestoreCallback() throws {
        let manager = PiPManager {
            Text("Test")
        }
        
        var callbackInvoked = false
        manager.onRestoreRequested = {
            callbackInvoked = true
        }
        
        XCTAssertNotNil(manager.onRestoreRequested, "Restore callback should be set")
        manager.onRestoreRequested?()
        XCTAssertTrue(callbackInvoked, "Callback should be invoked")
    }
}

