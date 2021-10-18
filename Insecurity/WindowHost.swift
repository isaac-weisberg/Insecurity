import UIKit

public class WindowHost: AdaptiveNavigation {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var navigationHostChild: NavigationHost?
    var modalHostChild: ModalHost?
    
    func _startModal<CoordinatorType: CommonModalCoordinator>(_ child: CoordinatorType,
                                                              duration: TimeInterval? = nil,
                                                              options: UIView.AnimationOptions? = nil,
                                                              _ completion: @escaping (CoordinatorResult<CoordinatorType.Result>) -> Void) {
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
                                                                        _ completion: @escaping (CoordinatorResult<CoordinatorType.Result>) -> Void) {
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
    
    public func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        
        _startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ initialChild: NavigationCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        _startNavigation(navigationController, initialChild, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        _startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ initialChild: AdaptiveCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        _startNavigation(navigationController, initialChild, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    // MARK: - AdaptiveNavigation
    
    public func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                                 in context: AdaptiveContext,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
        
        switch context {
        case .current, .modal:
            _startModal(child, duration: duration, options: options) { result in
                completion(result)
            }
        case .navigation(let navigationController):
            _startNavigation(navigationController, child, duration: duration, options: options) { result in
                completion(result)
            }
        }
    }
    
    public func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
    
        _startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ child: NavigationCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
        
        _startNavigation(navigationController, child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public var topContext: AdaptiveNavigation! {
        if let navigationHostChild = navigationHostChild {
            assert(modalHostChild == nil, "WindowHost is seeking topContext in the middle of transition between 2 children. Undefined behavior.")
            return navigationHostChild.topContext
        }
        if let modalHostChild = modalHostChild {
            assert(navigationHostChild == nil, "WindowHost is seeking topContext in the middle of transition between 2 children. Undefined behavior.")
            return modalHostChild.topContext
        }
        return self
    }
}
