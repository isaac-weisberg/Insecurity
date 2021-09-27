import UIKit

public class WindowCoordinator {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var navitrollerChild: NavitrollerCoordinatorAny?
    
    public func startNavitroller<NewResult>(_ navigationController: UINavigationController,
                                            _ initialChild: NavichildCoordinator<NewResult>,
                                            _ completion: @escaping (NewResult) -> Void) {
        let navitroller = NavitrollerCoordinator<NewResult>(navigationController, initialChild) { [weak self] result in
            guard let self = self else { return }
            
            self.navitrollerChild = nil
            
            completion(result)
        }
        
        self.navitrollerChild = navitroller
        
        window?.rootViewController = navigationController
    }
}
