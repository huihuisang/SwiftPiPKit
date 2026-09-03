import XCTest
import UIKit
@testable import SwiftPiPKit

/// Regression tests for `attachActiveSourceView`
///
/// The attach path used to re-dispatch itself on the main queue for as long as the source view had
/// no window, with no delay and no attempt limit. A view that never joined a window - a controller
/// SwiftUI builds and discards - turned that into an endless main-queue loop: 100% CPU for the rest
/// of the process lifetime (reported as `MXCPUException`) plus a leak of the captured view.
final class PiPManagerAttachTests: XCTestCase {

    /// A view already in a window is attached synchronously, with nothing left pending
    func testAttachSucceedsImmediatelyWhenViewIsInWindow() {
        let manager = PiPManager()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        window.addSubview(view)

        manager.attachActiveSourceView(view)

        XCTAssertNil(manager.pendingSourceView, "Attach should complete without waiting")
        XCTAssertFalse(manager.isAttachRetryScheduled, "No retry should be scheduled")
        XCTAssertEqual(manager.pendingAttachAttempts, 0)
    }

    /// A view that never joins a window makes the manager give up instead of spinning forever
    func testAttachGivesUpWhenViewNeverJoinsWindow() {
        let manager = PiPManager()
        let orphan = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        manager.attachActiveSourceView(orphan)

        XCTAssertTrue(manager.isAttachRetryScheduled, "The wait should be scheduled, not spun")
        XCTAssertTrue(manager.pendingSourceView === orphan)

        // Give-up point is maxAttachAttempts * attachRetryInterval, with slack for a loaded machine
        let budget = Double(PiPManager.maxAttachAttempts) * PiPManager.attachRetryInterval
        let stopped = pump(until: { manager.pendingSourceView == nil }, timeout: budget * 3)

        XCTAssertTrue(stopped, "Attach retries must terminate for a view that never gets a window")
        XCTAssertEqual(manager.pendingAttachAttempts, PiPManager.maxAttachAttempts)

        // And nothing reschedules itself after the give-up
        _ = pump(until: { false }, timeout: PiPManager.attachRetryInterval * 3)
        XCTAssertFalse(manager.isAttachRetryScheduled)
        XCTAssertNil(manager.pendingSourceView)
    }

    /// Releasing the source view ends the wait early - the manager must not keep it alive
    func testAttachStopsAndReleasesWhenSourceViewIsDeallocated() {
        let manager = PiPManager()
        weak var weakView: UIView?

        autoreleasepool {
            let orphan = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            weakView = orphan
            manager.attachActiveSourceView(orphan)
        }

        XCTAssertNil(weakView, "The pending source view must be held weakly")

        let stopped = pump(until: { !manager.isAttachRetryScheduled }, timeout: PiPManager.attachRetryInterval * 10)
        XCTAssertTrue(stopped, "Retries must stop once the source view is gone")
        XCTAssertLessThan(manager.pendingAttachAttempts, PiPManager.maxAttachAttempts)
    }

    /// Repeated attach calls share a single pending retry instead of stacking timers
    func testRepeatedAttachCallsDoNotStackRetries() {
        let manager = PiPManager()
        let orphan = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        for _ in 0 ..< 10 {
            manager.attachActiveSourceView(orphan)
        }

        XCTAssertTrue(manager.isAttachRetryScheduled)
        XCTAssertEqual(manager.pendingAttachAttempts, 1, "Retries should be coalesced into one pending tick")
    }

    // MARK: - Helpers

    /// Runs the main run loop until `condition` holds or `timeout` elapses, so scheduled retries fire
    private func pump(until condition: () -> Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }
        return condition()
    }
}
