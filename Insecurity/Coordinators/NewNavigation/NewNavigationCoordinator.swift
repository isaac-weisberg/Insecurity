import UIKit

class NewNavigationCoordinator<NavigationCoordinator: CommonNavigationCoordinator>: CommonNewNavigationCoordinatorAny {
    let navigationCoordinator: NavigationCoordinator
    
    init(_ navigationCoordinator: NavigationCoordinator) {
        self.navigationCoordinator = navigationCoordinator
    }
    
    func bindToHost(_ navigation: NavigationControllerNavigation,
                    _ navigationController: UINavigationController,
                    _ onFinish: @escaping (NavigationCoordinator.Result?, FinalizationKind) -> Void) -> UIViewController {
        
        weak var weakNavigationController: UIViewController? = navigationController
        weak var kvoContext: InsecurityKVOContext?
        
        let controller = navigationCoordinator.bindToHost(navigation) { result, finalizationKind in
            if let kvoContext = kvoContext {
                weakNavigationController?.insecurityKvo.removeObserver(kvoContext)
            }
            onFinish(result, finalizationKind)
        }
        
        kvoContext = navigationController.insecurityKvo.addHandler(
            UIViewController.self,
            modalParentObservationKeypath
        ) { oldController, newController in
            if oldController != nil, newController == nil {
                if let kvoContext = kvoContext {
                    weakNavigationController?.insecurityKvo.removeObserver(kvoContext)
                }
                
                onFinish(nil, .kvo)
            }
        }
        
        navigationController.setViewControllers([controller], animated: Insecurity.navigationControllerRootIsAssignedWithAnimation)
        
        return controller
    }
}
