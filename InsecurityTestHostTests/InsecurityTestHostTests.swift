@testable import Insecurity
@testable import InsecurityTestHost
import XCTest
import Nimble

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
        
        assert(rootController.presentedViewController == coordinator.state.instantiatedVCIfLive)
        assert(coordinator.state.isLive(hasChild: false))
        assert(coordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit != nil)
        
        let finishDismissFinished = XCTestExpectation()
        
        coordinator.finish((), source: .result, onDismissCompleted: {
            finishDismissFinished.fulfill()
        })
        
        assert(coordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(rootController.presentedViewController != nil)
        
        wait(for: finishDismissFinished)
        assert(coordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(rootController.presentedViewController == nil)
    }
    
    func testFinishCallButThereIsALiveChildOnTop() {
        let coordinator = ControlableCoordinator()
        
        let presentCompleted = XCTestExpectation()
        
        coordinator.mount(on: rootController, animated: true) { void in
            
        } onPresentCompleted: {
            presentCompleted.fulfill()
        }
    
        wait(for: presentCompleted)
        
        let childCoordinator = ControlableCoordinator()
        
        let childPresentCompleted = XCTestExpectation()
        
        coordinator.start(childCoordinator, animated: true) { void in
            
        } onPresentCompleted: {
            childPresentCompleted.fulfill()
        }
        
        wait(for: childPresentCompleted)
        
        assert(coordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit != nil)
        assert(childCoordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit != nil)
        assert(rootController.presentedViewController == coordinator.state.instantiatedVCIfLive)
        assert(coordinator.state.isLive(child: childCoordinator))
        expect(childCoordinator.state.isLive(child: nil)) == true
        
        let finishDismissFinished = XCTestExpectation()
        
        coordinator.finish((), source: .result, onDismissCompleted: {
            finishDismissFinished.fulfill()
        })
        
        assert(coordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit == nil)
        assert(childCoordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(childCoordinator.state.isDead)
        expect(self.rootController.presentedViewController).toNot(beNil())
        expect(self.rootController.modalChildrenChain.count) == 2
        
        wait(for: finishDismissFinished)
        assert(coordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit == nil)
        assert(childCoordinator.state.instantiatedVCIfLive?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(childCoordinator.state.isDead)
        assert(rootController.presentedViewController == nil)
        expect(self.rootController.modalChildrenChain).to(beEmpty())
    }
    
    func testFinishChain() {
        let coordinatorsThatStay = create(count: 4, of: ControlableCoordinator.init)
        let coordinatorsThatFinish = create(count: 6, of: ControlableCoordinator.init)
        
        let coordinators = coordinatorsThatStay + coordinatorsThatFinish
        
        let presentCompleted = XCTestExpectation()
        
        coordinators[0].mount(on: rootController, animated: true) { _ in
            
        } onPresentCompleted: {
            presentCompleted.fulfill()
        }
        
        wait(for: presentCompleted)
        
        var lastHandledCoordinator = coordinators[0]
        for (index, coordinator) in coordinators.enumerated().suffix(coordinators.count - 1) {
            let presentCompleted = XCTestExpectation()
            let parentCoordinator = lastHandledCoordinator
            
            parentCoordinator.start(coordinator, animated: true, { _ in
                if index > coordinatorsThatStay.count {
                    parentCoordinator.finish(())
                }
            }, onPresentCompleted: {
                presentCompleted.fulfill()
            })
            
            wait(for: presentCompleted)
            lastHandledCoordinator = coordinator
        }
        
        expect(coordinators.map(\.state.isLive)).to(allPass(beTrue()))
        
        let finishChainFinished = XCTestExpectation()
        
        coordinators.last!.finish((), source: .result) {
            finishChainFinished.fulfill()
        }
        
        expect(coordinatorsThatStay.map(\.state.isLive)).to(allPass(beTrue()))
        expect(coordinatorsThatFinish.map(\.state.isDead)).to(allPass(beTrue()))
        expect(self.rootController.modalChildrenChain).to(haveCount(coordinators.count))
        
        wait(for: finishChainFinished)
        
        expect(coordinatorsThatStay.map(\.state.isLive)).to(allPass(beTrue()))
        expect(coordinatorsThatFinish.map(\.state.isDead)).to(allPass(beTrue()))
        expect(self.rootController.modalChildrenChain).to(haveCount(coordinatorsThatStay.count))
        
        let cleanedUp = XCTestExpectation()
        
        coordinators.first!.finish((), source: .result) {
            cleanedUp.fulfill()
        }
        
        expect(coordinatorsThatStay.map(\.state.isDead)).to(allPass(beTrue()))
        
        wait(for: cleanedUp)
        
        expect(self.rootController.modalChildrenChain).to(beEmpty())
    }
    
    func testDismissWorksAsExpected() {
        let coordinatorsThatStay = create(count: 4, of: ControlableCoordinator.init)
        let coordinatorsThatFinish = create(count: 6, of: ControlableCoordinator.init)
        
        let coordinators = coordinatorsThatStay + coordinatorsThatFinish
        
        let presentCompleted = XCTestExpectation()
        
        coordinators[0].mount(on: rootController, animated: true) { _ in
            
        } onPresentCompleted: {
            presentCompleted.fulfill()
        }
        
        wait(for: presentCompleted)
        
        var lastHandledCoordinator = coordinators[0]
        for (index, coordinator) in coordinators.enumerated().suffix(coordinators.count - 1) {
            let presentCompleted = XCTestExpectation()
            let parentCoordinator = lastHandledCoordinator
            
            parentCoordinator.start(coordinator, animated: true, { _ in
                if index > coordinatorsThatStay.count {
                    parentCoordinator.finish(())
                }
            }, onPresentCompleted: {
                presentCompleted.fulfill()
            })
            
            wait(for: presentCompleted)
            lastHandledCoordinator = coordinator
        }
        
        expect(coordinators.map(\.state.isLive)).to(allPass(beTrue()))
        expect(self.rootController.modalChildrenChain).to(haveCount(coordinators.count))
        
        let dismissed = XCTestExpectation()
        
        coordinatorsThatStay.last!.dismissChildren(animated: true) {
            dismissed.fulfill()
        }
        
        expect(coordinatorsThatStay.map(\.state.isLive)).to(allPass(beTrue()))
        expect(coordinatorsThatFinish.map(\.state.isDead)).to(allPass(beTrue()))
        expect(self.rootController.modalChildrenChain).to(haveCount(coordinators.count))
        
        wait(for: dismissed)
        
        expect(self.rootController.modalChildrenChain).to(haveCount(coordinatorsThatStay.count))
        
        let cleanedUp = XCTestExpectation()
        
        coordinators.first!.finish((), source: .result) {
            cleanedUp.fulfill()
        }
        
        expect(coordinatorsThatStay.map(\.state.isDead)).to(allPass(beTrue()))
        
        wait(for: cleanedUp)
        
        expect(self.rootController.modalChildrenChain).to(beEmpty())
    }
}
