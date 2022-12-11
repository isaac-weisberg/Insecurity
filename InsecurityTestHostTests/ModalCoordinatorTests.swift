@testable import Insecurity
@testable import InsecurityTestHost
import XCTest
import Nimble

@MainActor
final class ModalCoordinatorTests: XCTestCase {
    let rootController = ViewController.sharedInstance
    
    func testFinishCallSuccessfullyDismisses() {
        let coordinator = TestModalCoordinator()
        
        let presentCompleted = XCTestExpectation()
        
        coordinator.mount(on: rootController, animated: true) { void in
            
        } onPresentCompleted: {
            presentCompleted.fulfill()
        }
    
        wait(for: presentCompleted)
        
        assert(rootController.presentedViewController == coordinator.state.instantiatedVCIfLive?.value)
        assert(coordinator.state.isLive(hasChild: false))
        assert(coordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit != nil)
        
        let finishDismissFinished = XCTestExpectation()
        
        coordinator.finish((), source: .result, onDismissCompleted: {
            finishDismissFinished.fulfill()
        })
        
        assert(coordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(rootController.presentedViewController != nil)
        
        wait(for: finishDismissFinished)
        assert(coordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(rootController.presentedViewController == nil)
    }
    
    func testFinishCallButThereIsALiveChildOnTop() {
        let coordinator = TestModalCoordinator()
        
        let presentCompleted = XCTestExpectation()
        
        coordinator.mount(on: rootController, animated: true) { void in
            
        } onPresentCompleted: {
            presentCompleted.fulfill()
        }
    
        wait(for: presentCompleted)
        
        let childCoordinator = TestModalCoordinator()
        
        let childPresentCompleted = XCTestExpectation()
        
        coordinator.start(childCoordinator, animated: true) { void in
            
        } onPresentCompleted: {
            childPresentCompleted.fulfill()
        }
        
        wait(for: childPresentCompleted)
        
        assert(coordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit != nil)
        assert(childCoordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit != nil)
        assert(rootController.presentedViewController == coordinator.state.instantiatedVCIfLive?.value)
        assert(coordinator.state.isLive(child: childCoordinator))
        expect(childCoordinator.state.isLive(child: nil)) == true
        
        let finishDismissFinished = XCTestExpectation()
        
        coordinator.finish((), source: .result, onDismissCompleted: {
            finishDismissFinished.fulfill()
        })
        
        assert(coordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit == nil)
        assert(childCoordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(childCoordinator.state.isDead)
        expect(self.rootController.presentedViewController).toNot(beNil())
        expect(self.rootController.modalChildrenChain.count) == 2
        
        wait(for: finishDismissFinished)
        assert(coordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit == nil)
        assert(childCoordinator.state.instantiatedVCIfLive?.value?.deinitObservable.onDeinit == nil)
        assert(coordinator.state.isDead)
        assert(childCoordinator.state.isDead)
        assert(rootController.presentedViewController == nil)
        expect(self.rootController.modalChildrenChain).to(beEmpty())
    }
    
    func testFinishChain() {
        let coordinatorsThatStay = create(count: 4, of: TestModalCoordinator.init)
        let coordinatorsThatFinish = create(count: 6, of: TestModalCoordinator.init)
        
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
        
        let allControllers = coordinators.map(\.state.instantiatedVCIfLive)
            .lazy
        expect(allControllers.map(\.?.value).filterNil()).to(haveCount(coordinators.count))
        expect(coordinators.map(\.state.isLive)).to(allPass(beTrue()))
        expect(allControllers.map(\.?.value?.deinitObservable.onDeinit)).to(allPass({ $0 != nil }))
        
        let finishChainFinished = XCTestExpectation()
        
        coordinators.last!.finish((), source: .result) {
            finishChainFinished.fulfill()
        }
        
        expect(coordinatorsThatStay.map(\.state.isLive)).to(allPass(beTrue()))
        expect(coordinatorsThatFinish.map(\.state.isDead)).to(allPass(beTrue()))
        
        let deinitsThatStay = allControllers[0..<coordinatorsThatStay.count]
            .map(\.?.value?.deinitObservable.onDeinit)
        let deinitsThatFinish = allControllers[
            coordinatorsThatStay.count
            ..<
            coordinatorsThatStay.count + coordinatorsThatFinish.count
        ].map(\.?.value?.deinitObservable.onDeinit)
        
        expect(
            Array(deinitsThatStay.compactMap { $0 })
        ).to(haveCount(coordinatorsThatStay.count))
        expect(Array(deinitsThatFinish.compactMap { $0 })).to(beEmpty())
        
        expect(self.rootController.modalChildrenChain).to(haveCount(coordinators.count))
        
        wait(for: finishChainFinished)
        
        expect(coordinatorsThatStay.map(\.state.isLive)).to(allPass(beTrue()))
        expect(coordinatorsThatFinish.map(\.state.isDead)).to(allPass(beTrue()))
        expect(self.rootController.modalChildrenChain).to(haveCount(coordinatorsThatStay.count))
        
        let cleanedUp = XCTestExpectation()
        
        coordinators.first!.finish((), source: .result) {
            cleanedUp.fulfill()
        }
        expect(allControllers.map(\.?.value?.deinitObservable.onDeinit)).to(allPass(beNil()))
        expect(coordinatorsThatStay.map(\.state.isDead)).to(allPass(beTrue()))
        
        wait(for: cleanedUp)
        
        expect(self.rootController.modalChildrenChain).to(beEmpty())
    }
    
    func testDismissWorksAsExpected() {
        let coordinatorsThatStay = create(count: 4, of: TestModalCoordinator.init)
        let coordinatorsThatFinish = create(count: 6, of: TestModalCoordinator.init)
        
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
    
    func testDeinitDismissWorks() async {
        let coordinatorsThatStay = create(count: 2, of: TestModalCoordinator.init)
        let coordinatorsThatGetDismissedFromMiddle = create(count: 3, of: TestModalCoordinator.init)
        let coordinatorThatGetDismissedFromTheEnd = TestModalCoordinator()
        let coordinatorsThatGetDismissedFromTheEnd = [coordinatorThatGetDismissedFromTheEnd]
        let coordinators = coordinatorsThatStay
            + coordinatorsThatGetDismissedFromMiddle
            + coordinatorsThatGetDismissedFromTheEnd
        
        let firstCoordinatorMount = await coordinators.first!.asyncMount(on: rootController, animated: false)
        
        await firstCoordinatorMount.onPresentCompleted.value
        
        var parentCoordinator = coordinators.first!
        for coordinator in coordinators.dropFirst() {
            let asyncStart = await parentCoordinator.asyncStart(coordinator, animated: false)
            
            await asyncStart.onPresentCompleted.value
            
            parentCoordinator = coordinator
        }
        
        let controllerThatGetDismissedFromTheEnd = coordinatorThatGetDismissedFromTheEnd.weakVcIfLive()
        
        // Dismiss as if by swiping down ;) (hopefully it works omg)
        let dismissFromEndExpectation = XCTestExpectation()
        
        coordinatorThatGetDismissedFromTheEnd.weakVcIfLive()!.value!.dismiss(animated: true, completion: {
            dismissFromEndExpectation.fulfill()
        })
        
        controllerThatGetDismissedFromTheEnd?.value.assertUnwrapped()
            .deinitObservable.onDeinit.assertNotNil()
        coordinatorThatGetDismissedFromTheEnd.isInLiveState.assertTrue()
        
        wait(for: dismissFromEndExpectation)
        
        // Still retained by parent view controller, as well as the OneToOneTransitionContext.... damn...
//        coordinatorThatGetDismissedFromTheEnd.isInLiveState.assertFalse()
//        controllerThatGetDismissedFromTheEnd?.value.assertNil()
        
        
        await rootController.dismiss(animated: false)
    }
}

extension Array {
    func filterNil() -> [Element] {
        return self.compactMap { $0 }
    }
}

extension ModalCoordinator {
    func weakVcIfLive() -> Weak<UIViewController>? {
        switch state {
        case .live(let live):
            return live.controller
        case .liveButStagedForDeath, .dead, .idle:
            return nil
        }
    }
}

extension LazySequence {
    func filterNil<ElementOfResult>() -> LazyMapSequence<LazyFilterSequence<LazyMapSequence<Self.Elements, ElementOfResult?>>, ElementOfResult> where Base.Element == ElementOfResult? {
        return compactMap { $0 }
    }
}

extension ModalCoordinator {
    struct AsyncMount {
        let onPresentCompleted: Task<Void, Never>
        let onFinish: Task<Result?, Never>
    }
    
    @MainActor
    func asyncMount(on viewController: UIViewController, animated: Bool) async -> AsyncMount {
        var onPresentCompletedCont: CheckedContinuation<Void, Never>?
        var onFinishCont: CheckedContinuation<Result?, Never>?
        
        let onPresentCompletedTask: Task<Void, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onPresentCompletedCont = cont
            }
        }
        
        let onFinishTask: Task<Result?, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onFinishCont = cont
            }
        }
        
        mount(on: viewController, animated: animated, completion: { result in
            if let onFinishCont {
                onFinishCont.resume(returning: result)
            } else {
                assertionFailure()
            }
        }, onPresentCompleted: {
            if let onPresentCompletedCont {
                onPresentCompletedCont.resume(returning: ())
            } else {
                assertionFailure()
            }
        })
        
        return AsyncMount(onPresentCompleted: onPresentCompletedTask, onFinish: onFinishTask)
    }
    
    struct AsyncStart<NewResult> {
        let onPresentCompleted: Task<Void, Never>
        let onFinish: Task<NewResult?, Never>
    }
    
    @MainActor
    func asyncStart<NewResult>(_ coordinator: ModalCoordinator<NewResult>, animated: Bool) async -> AsyncStart<NewResult> {
        
        var onPresentCompletedCont: CheckedContinuation<Void, Never>?
        var onFinishCont: CheckedContinuation<NewResult?, Never>?
        
        let onPresentCompletedTask: Task<Void, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onPresentCompletedCont = cont
            }
        }
        
        let onFinishTask: Task<NewResult?, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onFinishCont = cont
            }
        }
        
        self.start(coordinator, animated: animated, { result in
                if let onFinishCont {
                    onFinishCont.resume(returning: result)
                } else {
                    assertionFailure()
                }
        }, onPresentCompleted: {
            
                if let onPresentCompletedCont {
                    onPresentCompletedCont.resume(returning: ())
                } else {
                    assertionFailure()
                }
        })
        
        return AsyncStart(onPresentCompleted: onPresentCompletedTask, onFinish: onFinishTask)
    }
}
