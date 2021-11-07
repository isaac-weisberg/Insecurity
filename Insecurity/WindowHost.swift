import UIKit

public class WindowHost {
    weak var window: UIWindow?
    
    public init(_ window: UIWindow) {
        self.window = window
    }
    
    var insecurityHost: InsecurityHost?
    
    func startModal<Coordinator: CommonModalCoordinator>(_ child: Coordinator,
                                                         duration: TimeInterval? = nil,
                                                         options: UIView.AnimationOptions? = nil,
                                                         _ completion: @escaping (Coordinator.Result?) -> Void) {
        guard let window = window else {
            return
        }
        
        let controller = child.viewController
        let host = InsecurityHost(modal: controller)
        
        child._updateHostReference(host)
        child._finishImplementation = { [weak self] result in
            self?.insecurityHost?.kill()
            self?.insecurityHost = nil
            completion(result)
        }
        
        insecurityHost?.kill()
        insecurityHost = nil
        
        insecurityHost = host
        
        window.rootViewController = controller
        
        if let duration = duration, let options = options {
            UIView.transition(with: window,
                              duration: duration,
                              options: options,
                              animations: {},
                              completion: nil)
        }
    }
    
    func startNavigation<Coordinator: CommonNavigationCoordinator>(_ navigationController: UINavigationController,
                                                                   _ initialChild: Coordinator,
                                                                   duration: TimeInterval? = nil,
                                                                   options: UIView.AnimationOptions? = nil,
                                                                   _ completion: @escaping (Coordinator.Result?) -> Void) {
        guard let window = window else {
            return
        }
        
        navigationController.setViewControllers([ initialChild.viewController ], animated: Insecurity.navigationControllerRootIsAssignedWithAnimation)
        
        let host = InsecurityHost(navigation: navigationController)
        
        initialChild._updateHostReference(host)
        initialChild._finishImplementation = { [weak self] result in
            self?.insecurityHost?.kill()
            self?.insecurityHost = nil
            completion(result)
        }

        
        insecurityHost?.kill()
        insecurityHost = nil
        
        insecurityHost = host
        
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
        insecPrint("\(type(of: self)) deinit")
    }
#endif
    
    public func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult?) -> Void) {
        
        startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ initialChild: NavigationCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult?) -> Void) {
        startNavigation(navigationController, initialChild, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult?) -> Void) {
        startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ initialChild: AdaptiveCoordinator<NewResult>,
                                 duration: TimeInterval? = nil,
                                 options: UIView.AnimationOptions? = nil,
                                 _ completion: @escaping (NewResult?) -> Void) {
        startNavigation(navigationController, initialChild, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public var topContext: AdaptiveNavigation! {
        if let insecurityHost = insecurityHost {
            return insecurityHost
        }
        return self
    }
}

extension WindowHost: AdaptiveNavigation {
    public func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                                 in context: AdaptiveContext,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
        
        switch context._internalContext {
        case .current, .modal:
            startModal(child, duration: duration, options: options) { result in
                completion(result)
            }
        case .newNavigation(let navigationController):
            startNavigation(navigationController, child, duration: duration, options: options) { result in
                completion(result)
            }
        case .currentNavigation(let defferredNavigationController):
            let navigationController = defferredNavigationController.make()
            
            startNavigation(navigationController, child, duration: duration, options: options) { result in
                completion(result)
            }
        }
    }
    
    public func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
        
        startModal(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ child: NavigationCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
        
        startNavigation(navigationController, child, duration: duration, options: options) { result in
            completion(result)
        }
    }
}
