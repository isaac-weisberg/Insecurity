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
    
    var navigationCoordinatorChild: NavigationCoordinatorAny?
    var modalCoordinatorChild: ModalCoordinatorAny?
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                                      duration: TimeInterval? = nil,
                                      options: UIView.AnimationOptions? = nil,
                                      _ completion: @escaping (NewResult) -> Void) {
        guard let window = window else {
            assertionFailure("Window Coordinator attempted to start a child on a dead window")
            return
        }
        
        let controller = child.viewController
        let modalCoordinator = ModalCoordinator(controller)
        child._navigation = modalCoordinator
        child._finishImplementation = { [weak self] result in
            self?.modalCoordinatorChild = nil
            completion(result)
        }
        self.navigationCoordinatorChild = nil // Just in case...
        self.modalCoordinatorChild = modalCoordinator
        
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
        
        let navigationCoordinator = NavigationCoordinator(navigationController)
        
        initialChild._navigation = navigationCoordinator
        initialChild._finishImplementation = { [weak self] result in
            self?.navigationCoordinatorChild = nil
            completion(result)
        }
        
        navigationController.setViewControllers([ initialChild.viewController ], animated: Insecurity.navigationControllerRootIsAssignedWithAnimation)
        
        self.modalCoordinatorChild = nil // Just in case...
        self.navigationCoordinatorChild = navigationCoordinator
        
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
        if let navigationCoordinatorChild = navigationCoordinatorChild {
            assert(modalCoordinatorChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            navigationCoordinatorChild.startOverTop(child, animated: animated) { result in
                completion(result)
            }
            return
        }
        if let modalCoordinatorChild = modalCoordinatorChild {
            assert(navigationCoordinatorChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            modalCoordinatorChild.startOverTop(child, animated: animated) { result in
                completion(result)
            }
            return
        }
        self.startModal(child) { result in
            completion(.normal(result))
        }
    }
}
