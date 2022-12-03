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
        
        assert(coordinator.state.isLive)
    }
}

extension ModalCoordinator.State {
    var isLive: Bool {
        switch self {
        case .live:
            return true
        case .dead, .idle:
            return false
        }
    }
}

extension XCTestCase {
    func wait(for expectation: XCTestExpectation, timeout: TimeInterval? = nil) {
        self.wait(for: [expectation], timeout: timeout ?? 5)
    }
}
