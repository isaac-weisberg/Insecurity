@testable import Insecurity
@testable import InsecurityTestHost
import XCTest

final class InsecurityTestHostTests: XCTestCase {
    
    func testFinishCallSuccessfullyDismisses() {
        let rootController = ViewController.sharedInstance
        
        let coordinator = ControlableCoordinator()
        
        let presentCompleted = XCTestExpectation()
        
        coordinator.mount(on: rootController, animated: true) { void in
            
        } onPresentCompleted: {
            presentCompleted.fulfill()
        }
    
        wait(for: presentCompleted)
        
        assert(rootController.presentedViewController == coordinator.instantiatedViewController)
        assert(coordinator.state.isLive(hasChild: false))
        
        let finishDismissFinished = XCTestExpectation()
        
        coordinator.finish((), source: .result, onDismissCompleted: {
            finishDismissFinished.fulfill()
        })
        
        assert(coordinator.state.isDead)
        assert(rootController.presentedViewController != nil)
        
        wait(for: finishDismissFinished)
        assert(coordinator.state.isDead)
        assert(rootController.presentedViewController == nil)
    }
}

extension ModalCoordinator.State {
    func isLive(hasChild: Bool) -> Bool {
        switch self {
        case .live(let live):
            if hasChild {
                return live.child != nil
            } else {
                return live.child == nil
            }
        case .dead, .idle:
            return false
        }
    }
    
    var isLive: Bool {
        switch self {
        case .live:
            return true
        case .dead, .idle:
            return false
        }
    }
    
    var isDead: Bool {
        switch self {
        case .dead:
            return true
        case .live, .idle:
            return false
        }
    }
}

extension XCTestCase {
    func wait(for expectation: XCTestExpectation, timeout: TimeInterval? = nil) {
        self.wait(for: [expectation], timeout: timeout ?? 5)
    }
}
