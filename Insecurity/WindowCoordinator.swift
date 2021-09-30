import UIKit

open class WindowCoordinator {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var navitrollerChild: NavitrollerCoordinatorAny?
    var modarollerChild: ModarollerCoordinatorAny?
    
    public func startModaroller<NewResult>(_ modachild: ModachildCoordinator<NewResult>, _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        // Holy moly, I hope I don't regret these design choices
        let modaroller = ModarollerCoordinator<NewResult>(optionalHost: nil)
        let controller = modachild.make(modaroller) { [weak self] result in
            self?.modarollerChild = nil
            completion(result)
        }
        modaroller.host = controller
        self.modarollerChild = modaroller
        
        window.rootViewController = controller
    }
    
    public func startNavitroller<NewResult>(_ navigationController: UINavigationController,
                                            _ initialChild: NavichildCoordinator<NewResult>,
                                            _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        let navitroller = NavitrollerCoordinator<NewResult>(navigationController, initialChild) { [weak self] result in
            guard let self = self else { return }
            
            self.navitrollerChild = nil
            
            completion(result)
        }
        
        self.navitrollerChild = navitroller
        
        window.rootViewController = navigationController
    }
    
    #if DEBUG
    deinit {
        print("Window Coordinator deinit \(type(of: self))")
    }
    #endif
}
