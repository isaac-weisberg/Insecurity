import XCTest
@testable import Insecurity
@testable import InsecurityTestHost
import Nimble

class NavigationCoordinatorTests: XCTestCase {
    @MainActor
    func testFinishWorks() async {
        let coordinator = TestNavigationCoordinator<Void>()
        
        let navigationController = UINavigationController()
        
        coordinator.mount(on: navigationController) { result in
            
        }
        
        await ViewController.sharedInstance.present(navigationController, animated: true)
        
        let child = TestNavigationCoordinator<Int>()
        
        coordinator.start(child, animated: true) { result in
            
        }
        
        await awaitAnims()
        
        let childController = child.weakVcIfLive!
        
        assert(coordinator.state.isLive)
        assert(coordinator.vcIfLive!.hasDeinitObservable)
        assert(child.state.isLive)
        assert(childController.value!.hasDeinitObservable)
        expect(navigationController.viewControllers) == [coordinator.vcIfLive!, child.vcIfLive]
        
        child.finish(3)
        
        assert(coordinator.state.isLive)
        assert(child.state.isDead)
        assert(coordinator.vcIfLive!.hasDeinitObservable)
        assert(childController.value!.hasDeinitObservable.not)
        
        await awaitAnims()
        
        assert(coordinator.state.isLive)
        assert(child.state.isDead)
        assert(coordinator.vcIfLive!.hasDeinitObservable)
        
        assert(childController.value?.hasDeinitObservable == false)
        // Next is still stored on `navigationController` _disappearingViewController and UIViewAnimationBlockDelegate
        //        assert(childController.value == nil)
        expect(navigationController.viewControllers) == [coordinator.vcIfLive!]
        
        await ViewController.sharedInstance.dismiss(animated: true)
    }
    
    @MainActor
    func testDismissAllChildrenWorksAsExpected() async {
        let coordinatorsThatStay = create(count: 4, of: TestNavigationCoordinator<Void>.init)
        
        let coordinatorsThatGetDismissed = create(count: 5, of: TestNavigationCoordinator<Void>.init)
        
        let coordinators = coordinatorsThatStay + coordinatorsThatGetDismissed
        
        let navigationController = UINavigationController()
        
        await ViewController.sharedInstance.present(navigationController, animated: false)
        
        coordinators.first!.mount(on: navigationController, completion: { result in
            
        })
        
        var parentCoordinator = coordinators.first!
        for coordinator in coordinators.dropFirst() {
            parentCoordinator.start(coordinator, animated: false) { result in
                
            }
            
            parentCoordinator = coordinator
        }
        
        let controllersThatGetDismissed = coordinatorsThatGetDismissed.weakVcsIfLive().assertUnwrapped()
        coordinators.states().assertAllLive()
        coordinators.vcsIfLive().assertUnwrapped().deinitHandlers().assertAllNotNil()
        controllersThatGetDismissed.map(\.value).assertUnwrapped().deinitHandlers().assertAllNotNil()
        
        // Dismiss
        coordinatorsThatStay.last.assertUnwrapped().dismissChildren(animated: true)
        
        coordinatorsThatStay.vcsIfLive().assertUnwrapped().deinitHandlers().assertAllNotNil()
        coordinatorsThatStay.states().assertAllLive()
        
        coordinatorsThatGetDismissed.vcsIfLive().assertAllNil()
        coordinatorsThatGetDismissed.states().assertAllNotLive()
        controllersThatGetDismissed.map(\.value).assertUnwrapped().deinitHandlers().assertAllNil()
        
        await awaitAnims()
        
        // Last controller is again captured by _disappearingViewController and UIViewAnimationBlockDelegate
        controllersThatGetDismissed.dropLast().map(\.value).assertAllNil()
//        weakCoordinatorsThatGetDismissed.last!.value.assertNil()
        
        await ViewController.sharedInstance.dismiss(animated: false)
    }
}

func awaitAnims() async {
    await sleep(0.3)
}

extension NavigationCoordinator.State {
    var isLive: Bool {
        switch self {
        case .live:
            return true
        case .idle, .liveButStagedForDeath, .dead:
            return false
        }
    }
    
    var isDead: Bool {
        switch self {
        case .dead:
            return true
        case .live, .liveButStagedForDeath, .idle:
            return false
        }
    }
}

extension NavigationCoordinator {
    var weakVcIfLive: Weak<UIViewController>? {
        switch state {
        case .live(let live):
            return live.controller
        case .dead, .liveButStagedForDeath, .idle:
            return nil
        }
    }
    
    var vcIfLive: UIViewController? {
        switch state {
        case .live(let live):
            return live.controller.value
        case .dead, .liveButStagedForDeath, .idle:
            return nil
        }
    }
}

extension UIViewController {
    var hasDeinitObservable: Bool {
        return deinitObservable.onDeinit != nil
    }
}

extension Array {
    func states<Result>() -> [Element.State] where Element: NavigationCoordinator<Result> {
        return map(\.state)
    }
    
    func areAllLive<Result>() -> Bool where Element == NavigationCoordinator<Result>.State {
        return allSatisfy { $0.isLive }
    }
    
    func assertAllLive<Result>(file: String = #file, line: UInt = #line) where Element == NavigationCoordinator<Result>.State {
        expect(file: file, line: line, self).to(allPass({ $0.isLive }))
    }
    
    func assertAllNotLive<Result>(file: String = #file, line: UInt = #line) where Element == NavigationCoordinator<Result>.State {
        expect(file: file, line: line, self).to(allPass({ !$0.isLive }))
    }
    
    func weakVcsIfLive<Result>() -> [Weak<UIViewController>?] where Element: NavigationCoordinator<Result> {
        return map { $0.weakVcIfLive }
    }
    
    func vcsIfLive<Result>() -> [UIViewController?] where Element: NavigationCoordinator<Result> {
        return map { $0.weakVcIfLive?.value }
    }
    
    func deinitHandlers() -> [(() -> Void)?] where Element: UIViewController {
        self.map { $0.deinitObservable.onDeinit }
    }
}

extension Array {
    func assertUnwrapped<Wrapped>(file: String = #file, line: UInt = #line) -> [Wrapped] where Element == Optional<Wrapped> {
        self.assertAllNotNil(file: file, line: line)

        return map { $0! }
    }
    
    func assertAllNotNil<Wrapped>(file: String = #file, line: UInt = #line) where Element == Optional<Wrapped> {
        expect(file: file, line: line, self).to(allPass({ $0 != nil }))
    }
    
    func assertAllNil<Wrapped>(file: String = #file, line: UInt = #line) where Element == Optional<Wrapped> {
        expect(file: file, line: line, self).to(allPass(beNil()))
    }
}

extension Optional {
    func assertNotNil(file: String = #file, line: UInt = #line) {
        expect(file: file, line: line, self).toNot(beNil())
    }
    
    func assertNil(file: String = #file, line: UInt = #line) {
        expect(file: file, line: line, self).to(beNil())
    }
    
    func assertUnwrapped(file: String = #file, line: UInt = #line) -> Wrapped {
        assertNotNil(file: file, line: line)
        
        return self!
    }
}
