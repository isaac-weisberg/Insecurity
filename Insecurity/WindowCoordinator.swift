import UIKit

public protocol WindowCoordinatorAny: AnyObject {
    func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                               duration: TimeInterval?,
                               options: UIView.AnimationOptions?,
                               _ completion: @escaping (NewResult) -> Void)
    
    func startNavigation<NewResult>(_ navigationController: UINavigationController,
                                    _ initialChild: InsecurityChild<NewResult>,
                                    duration: TimeInterval?,
                                    options: UIView.AnimationOptions?,
                                    _ completion: @escaping (NewResult) -> Void)
    
    func startOverTop<NewResult>(_ child: InsecurityChild<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}

open class WindowCoordinator: WindowCoordinatorAny {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var navitrollerChild: NavitrollerCoordinatorAny?
    var modarollerChild: ModarollerCoordinatorAny?
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                                      duration: TimeInterval? = nil,
                                      options: UIView.AnimationOptions? = nil,
                                      _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        let controller = child.viewController
        let modaroller = ModarollerCoordinator(controller)
        child._navigation = modaroller
        child._finishImplementation = { [weak self] result in
            self?.modarollerChild = nil
            completion(result)
        }
        self.navitrollerChild = nil // Just in case...
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
    
    public func startNavigation<NewResult>(_ navigationController: UINavigationController,
                                           _ initialChild: InsecurityChild<NewResult>,
                                           duration: TimeInterval? = nil,
                                           options: UIView.AnimationOptions? = nil,
                                           _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        let navitroller = NavitrollerCoordinator(navigationController)
        
        initialChild._navigation = navitroller
        initialChild._finishImplementation = { [weak self] result in
            self?.navitrollerChild = nil
            completion(result)
        }
        
        navigationController.setViewControllers([ initialChild.viewController ], animated: navigationControllerRootIsAssignedWithAnimation)
        
        self.modarollerChild = nil // Just in case...
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
    
    public func startOverTop<NewResult>(_ child: InsecurityChild<NewResult>,
                                        animated: Bool,
                                        _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        if let navitrollerChild = navitrollerChild {
            assert(modarollerChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            navitrollerChild.startOverTop(child, animated: animated) { result in
                completion(result)
            }
            return
        }
        if let modarollerChild = modarollerChild {
            assert(navitrollerChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            modarollerChild.startOverTop(child, animated: animated) { result in
                completion(result)
            }
            return
        }
        self.startModal(child) { result in
            completion(.normal(result))
        }
    }
}
