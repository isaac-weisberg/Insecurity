import UIKit

open class WindowCoordinator {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var navitrollerChild: NavitrollerCoordinatorAny?
    var modarollerChild: ModarollerCoordinatorAny?
    
    public func startModaroller<NewResult>(_ make: @escaping (@escaping (NewResult) -> Void) -> UIViewController, _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        assert(navitrollerChild == nil, "Window Coordinator attempted to start a child when another navitrollerChild is still running")
        assert(modarollerChild == nil, "Window Coordinator attempted to start a child when another modarollerChild is still running")
        
        // Jesus Christ
        var createdController: UIViewController?
        
        let modaroller = ModarollerCoordinator<NewResult>({ finish in
            let controller = make(finish)
            createdController = controller
            return controller
        }, { [weak self] result in
            guard let self = self else {
                assertionFailure("Window Coordinator's Modal Coordinator child has ended, but the window coordinator is dead")
                return
            }
            self.modarollerChild = nil
            completion(result)
        })
        
        guard let createdController = createdController else {
            assertionFailure("Attempted to start a Modal Navigation Coordinator, but the Coordinator didn't bother to create a viewController, which is a bug")
            return
        }
        
        self.modarollerChild = modaroller
        window.rootViewController = createdController
    }
    
    public func startNavitroller<NewResult>(_ navigationController: UINavigationController,
                                            _ initialChild: NavichildCoordinator<NewResult>,
                                            _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        assert(navitrollerChild == nil, "Window Coordinator attempted to start a child when another navitrollerChild is still running")
        assert(modarollerChild == nil, "Window Coordinator attempted to start a child when another modarollerChild is still running")
        
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
