import UIKit

public protocol WindowCoordinatorAny: AnyObject {
    func startModaroller<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                    duration: TimeInterval?,
                                    options: UIView.AnimationOptions?,
                                    _ completion: @escaping (NewResult) -> Void)
    
    func startNavitroller<NewResult>(_ navigationController: UINavigationController,
                                     _ initialChild: NavichildCoordinator<NewResult>,
                                     duration: TimeInterval?,
                                     options: UIView.AnimationOptions?,
                                     _ completion: @escaping (NewResult) -> Void)
    
    func startOverTop<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}

public extension WindowCoordinatorAny {
    func start<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                          duration: TimeInterval? = nil,
                          options: UIView.AnimationOptions? = nil,
                          _ completion: @escaping (NewResult) -> Void) {
        startModaroller(modachild, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ initialChild: NavichildCoordinator<NewResult>,
                          duration: TimeInterval? = nil,
                          options: UIView.AnimationOptions? = nil,
                          _ completion: @escaping (NewResult) -> Void) {
        startNavitroller(navigationController, initialChild, duration: duration, options: options) { result in
            completion(result)
        }
    }
}

open class WindowCoordinator: WindowCoordinatorAny {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var navitrollerChild: NavitrollerCoordinatorAny?
    var modarollerChild: ModarollerCoordinatorAny?
    
    public func startModaroller<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                           duration: TimeInterval? = nil,
                                           options: UIView.AnimationOptions? = nil,
                                           _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        let controller = modachild.viewController
        let modaroller = ModarollerCoordinator(controller)
        modachild._modaroller = modaroller
        modachild._finishImplementation = { [weak self] result in
            self?.modarollerChild = nil
            completion(result)
        }
        self.modarollerChild = modaroller
        
        window.rootViewController = controller
        
        if let duration = duration, let options = options {
            UIView.transition(with: window,
                              duration: duration,
                              options: options,
                              animations: {},
                              completion: nil)
        }
    }
    
    public func startNavitroller<NewResult>(_ navigationController: UINavigationController,
                                            _ initialChild: NavichildCoordinator<NewResult>,
                                            duration: TimeInterval? = nil,
                                            options: UIView.AnimationOptions? = nil,
                                            _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        let navitroller = NavitrollerCoordinator(navigationController)
        
        initialChild._navitroller = navitroller
        initialChild._finishImplementation = { [weak self] result in
            self?.navitrollerChild = nil
            completion(result)
        }
        
        navigationController.setViewControllers([ initialChild.viewController ], animated: navigationControllerRootIsAssignedWithAnimation)
        
        self.navitrollerChild = navitroller
        
        window.rootViewController = navigationController
        
        if let duration = duration, let options = options {
            UIView.transition(with: window,
                              duration: duration,
                              options: options,
                              animations: {},
                              completion: nil)
        }
    }
    
#if DEBUG
    deinit {
        print("Window Coordinator deinit \(type(of: self))")
    }
#endif
    
    public func startOverTop<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                        animated: Bool,
                                        _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        if let navitrollerChild = navitrollerChild {
            assert(modarollerChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            navitrollerChild.startOverTop(modachild, animated: animated) { result in
                completion(result)
            }
            return
        }
        if let modarollerChild = modarollerChild {
            assert(navitrollerChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            modarollerChild.startOverTop(modachild, animated: animated) { result in
                completion(result)
            }
            return
        }
        self.startModaroller(modachild) { result in
            completion(.normal(result))
        }
    }
}
