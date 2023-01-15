import UIKit

open class NavigationRootCoordinator<Result>: ModalCoordinator<Result> {
    var _navigationCoordinator: _NavigationRootUnderlyingCoordinator<Result>!
    
    open override var viewController: UIViewController {
        // Override this
        fatalError()
    }
    
    open var navigationController: UINavigationController {
        // Also, override this
        fatalError()
    }
    
    func start<NewResult>(
        _ child: NavigationCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        _navigationCoordinator.start(child, animated: animated, { result in
            completion(result)
        })
    }
    
    override func mountOnControllerInternal(on parentViewController: UIViewController,
                                            animated: Bool,
                                            completion: @escaping (Result?) -> Void,
                                            onPresentCompleted: (() -> Void)?) {
        let navigationController = self.navigationController
        
        mountOnCtrlForCtrl(
            on: parentViewController,
            controller: navigationController,
            completion: { result in
                completion(result)
            })
        
        let controller = self.viewController
        
        let navigationCoordinator = _NavigationRootUnderlyingCoordinator(owner: self, vc: controller)
        
        navigationCoordinator.mountOnNavigationCoontroller(on: navigationController,
                                                           modalCoordinator: self.weak,
                                                           completion: { result in
            completion(result)
        })
        
        self._navigationCoordinator = navigationCoordinator
        
        parentViewController.present(navigationController, animated: animated, completion: {
            onPresentCompleted?()
        })
    }
    
    override func mount(on parent: CommonModalCoordinator,
                        completion: @escaping (Result?) -> Void) -> UIViewController {
        let controller = super.mount(on: parent, completion: { result in
            completion(result)
        })
        
        let navigationController = self.navigationController
        
        let navigationCoordinator = _NavigationRootUnderlyingCoordinator(owner: self, vc: controller)
        navigationCoordinator.mountOnNavigationCoontroller(
            on: navigationController,
            modalCoordinator: self.weak,
            completion: { result in
                completion(result)
            })
        
        self._navigationCoordinator = navigationCoordinator
        
        return navigationController
    }
}

class _NavigationRootUnderlyingCoordinator<Result>: NavigationCoordinator<Result> {
    unowned let owner: NavigationRootCoordinator<Result>
    
    var _cachedVC: UIViewController?
    
    override var viewController: UIViewController {
        let vc = _cachedVC!
        _cachedVC = nil
        return vc
    }
    
    init(owner: NavigationRootCoordinator<Result>, vc: UIViewController) {
        self.owner = owner
        self._cachedVC = vc
    }
}
