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
        await awaitAnims()
        
        assert(coordinator.state.isLive)
        assert(child.state.isDead)
        assert(coordinator.vcIfLive!.hasDeinitObservable)
        
        assert(childController.value?.hasDeinitObservable == false)
//        assert(childController.value == nil) // still stored on `navigationController` _disappearingViewController
        expect(navigationController.viewControllers) == [coordinator.vcIfLive!]
        
        await ViewController.sharedInstance.dismiss(animated: true)
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
