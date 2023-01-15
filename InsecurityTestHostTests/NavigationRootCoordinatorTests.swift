import XCTest
@testable import Insecurity
@testable import InsecurityTestHost
import Nimble

class NavigationRootCoordinatorTests: XCTestCase {
    let rootController = ViewController.sharedInstance
    
    @MainActor
    func testInnerCoordinatorsCanStartModalScreens() async {
        let navigationRootCoordinator = TestNavigationRootCoordinator()
        
        let innerCoordinator = TestNavigationCoordinator<Int>()
        
        navigationRootCoordinator.mount(on: rootController, animated: true, completion: { _ in })
        
        await awaitAnims()
        
        navigationRootCoordinator.start(innerCoordinator, animated: true, { _ in
            
        })
        
        await awaitAnims()
        
        unowned let navigationController: UINavigationController = (navigationRootCoordinator.state.vcIfLive! as! UINavigationController)
        
        expect(self.rootController.modalChildrenChain) == [navigationController]
        expect(navigationController.viewControllers) == [
            navigationRootCoordinator._navigationCoordinator.vcIfLive!,
            innerCoordinator.vcIfLive!
        ]
        
        let modalCoordinator = TestModalCoordinator()
        
        navigationRootCoordinator.start(modalCoordinator, animated: true) { _ in }
        
        await awaitAnims()
        
        expect(self.rootController.modalChildrenChain) == [
            navigationController,
            modalCoordinator.vcIfLive()!
        ]
        expect(navigationController.viewControllers) == [
            navigationRootCoordinator._navigationCoordinator.vcIfLive!,
            innerCoordinator.vcIfLive!
        ]
        
        await rootController.dismiss(animated: true)
    }
}
