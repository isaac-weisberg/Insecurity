import UIKit

public protocol WindowHostAny: AnyObject {
    func startOverTop<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          duration: TimeInterval?,
                          options: UIView.AnimationOptions?,
                          _ completion: @escaping (NewResult) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ initialChild: NavigationCoordinator<NewResult>,
                          duration: TimeInterval?,
                          options: UIView.AnimationOptions?,
                          _ completion: @escaping (NewResult) -> Void)
}

public class WindowHost: WindowHostAny {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var navigationHostChild: NavigationHostAny?
    var modalHostChild: ModalHostAny?
    
    func _startModal<CoordinatorType: CommonModalCoordinator>(_ child: CoordinatorType,
                                                              duration: TimeInterval? = nil,
                                                              options: UIView.AnimationOptions? = nil,
                                                              _ completion: @escaping (CoordinatorType.Result) -> Void) {
        guard let window = window else {
            assertionFailure("WindowHost attempted to start a child on a dead window")
            return
        }
        
        let controller = child.viewController
        let modalHost = ModalHost(controller)
        child._updateHostReference(modalHost)
        child._finishImplementation = { [weak self] result in
            self?.modalHostChild = nil
            completion(result)
        }
        self.navigationHostChild = nil // Just in case...
        self.modalHostChild = modalHost
        
        window.rootViewController = controller
        
        if let duration = duration, let options = options {
            UIView.transition(with: window,
                              duration: duration,
                              options: options,
                              animations: {},
                              completion: nil)
        }
    }
    
    func _startNavigation<CoordinatorType: CommonNavigationCoordinator>(_ navigationController: UINavigationController,
                                                                        _ initialChild: CoordinatorType,
                                                                        duration: TimeInterval? = nil,
                                                                        options: UIView.AnimationOptions? = nil,
                                                                        _ completion: @escaping (CoordinatorType.Result) -> Void) {
        guard let window = window else {
            assertionFailure("WindowHost attempted to start a child on a dead window")
            return
        }
        
        let navigationHost = NavigationHost(navigationController)
        
        initialChild._updateHostReference(navigationHost)
        initialChild._finishImplementation = { [weak self] result in
            self?.navigationHostChild = nil
            completion(result)
        }
        
        navigationController.setViewControllers([ initialChild.viewController ], animated: Insecurity.navigationControllerRootIsAssignedWithAnimation)
        
        self.modalHostChild = nil // Just in case...
        self.navigationHostChild = navigationHost
        
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
        print("WindowHost deinit \(type(of: self))")
    }
#endif
    
    public func startOverTop<NewResult>(_ child: ModalCoordinator<NewResult>,
                                        animated: Bool,
                                        _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        if let navigationHostChild = navigationHostChild {
            assert(modalHostChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            navigationHostChild.startOverTop(child, animated: animated) { result in
                completion(result)
            }
            return
        }
        if let modalHostChild = modalHostChild {
            assert(navigationHostChild == nil, "Window is starting over top in the middle of transition between 2 children. Undefined behavior.")
            modalHostChild.startOverTop(child, animated: animated) { result in
                completion(result)
            }
            return
        }
        _startModal(child) { result in
            completion(.normal(result))
        }
    }
    
    public func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult) -> Void) {
        
        _startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ initialChild: NavigationCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult) -> Void) {
        _startNavigation(navigationController, initialChild, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult) -> Void) {
        _startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ initialChild: AdaptiveCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult) -> Void) {
        _startNavigation(navigationController, initialChild, duration: duration, options: options) { result in
            completion(result)
        }
    }
}
