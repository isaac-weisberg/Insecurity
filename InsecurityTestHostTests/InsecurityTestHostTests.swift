@testable import Insecurity
@testable import InsecurityTestHost
import XCTest

final class InsecurityTestHostTests: XCTestCase {
    let rootController = ViewController.sharedInstance
    
    func testFinishCallSuccessfullyDismisses() {
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
    
    func testFinishChain() {
        let coordinatorsCount = 10
        let lastCoordinatorThatFinishes = 5
        let coordinators = (0..<coordinatorsCount).map { _ in
            ControlableCoordinator()
        }
        let presentCompleted = XCTestExpectation()
        
        coordinators[0].mount(on: rootController, animated: true) { _ in
            
        } onPresentCompleted: {
            presentCompleted.fulfill()
        }
        
        wait(for: presentCompleted)
        
        var parentCoordinator = coordinators[0]
        for (index, coordinator) in coordinators.enumerated().suffix(coordinatorsCount - 1) {
            let presentCompleted = XCTestExpectation()
            
            parentCoordinator.start(coordinator, animated: true, { _ in
                if index > lastCoordinatorThatFinishes {
                    parentCoordinator.finish(())
                }
            }, onPresentCompleted: {
                presentCompleted.fulfill()
            })
            
            wait(for: presentCompleted)
            parentCoordinator = coordinator
        }
        
        
        
    }
}
