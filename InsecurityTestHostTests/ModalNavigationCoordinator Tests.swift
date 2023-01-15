import XCTest
@testable import Insecurity
@testable import InsecurityTestHost
import Nimble

class ModalNavigationCoordinatorTests: XCTestCase {
    let rootController = ViewController.sharedInstance
    
    @MainActor
    func testInnerCoordinatorsCanStartModalScreens() async {
        let outerCoordinator = TestNavigationCoordinator<Void>()
        let modalRootCoordinator = outerCoordinator.modal(UINavigationController())
        
        let innerCoordinator = TestNavigationCoordinator<Int>()
        
        modalRootCoordinator.mount(on: rootController, animated: true, completion: { _ in })
        
        await awaitAnims()
        
        modalRootCoordinator.start(innerCoordinator, animated: true, { _ in
            
        })
        
        await awaitAnims()
        
        unowned let navigationController: UINavigationController = (modalRootCoordinator.state.vcIfLive! as! UINavigationController)
        
        expect(self.rootController.modalChildrenChain) == [navigationController]
        expect(navigationController.viewControllers) == [
            modalRootCoordinator.navigationCoordinator.vcIfLive!,
            innerCoordinator.vcIfLive!
        ]
        
        let modalCoordinator = TestModalCoordinator()
        
        modalRootCoordinator.start(modalCoordinator, animated: true) { _ in }
        
        await awaitAnims()
        
        expect(self.rootController.modalChildrenChain) == [
            navigationController,
            modalCoordinator.vcIfLive()!
        ]
        expect(navigationController.viewControllers) == [
            modalRootCoordinator.navigationCoordinator.vcIfLive!,
            innerCoordinator.vcIfLive!
        ]
        
        await rootController.dismiss(animated: true)
    }
}
