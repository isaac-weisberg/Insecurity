import UIKit

open class NavigationRootCoordinator<Result>: ModalCoordinator<Result> {
    private var navigationCoordinator: NavigationRootUnderlyingCoordinator<Result>!
    
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
        navigationCoordinator.start(child, animated: animated, { result in
            completion(result)
        })
    }
    
    override func mount(on parent: CommonModalCoordinator,
                        completion: @escaping (Result?) -> Void) -> UIViewController {
        let controller = super.mount(on: parent, completion: { result in
            completion(result)
        })
        
        let navigationController = self.navigationController
        
        let navigationCoordinator = NavigationRootUnderlyingCoordinator(owner: self, vc: controller)
        navigationCoordinator.mountOnNavigationCoontroller(
            on: navigationController,
            modalCoordinator: self.weak,
            completion: { result in
                fatalError()
            })
        
        self.navigationCoordinator = navigationCoordinator
        
        return navigationController
    }
}

private class NavigationRootUnderlyingCoordinator<Result>: NavigationCoordinator<Result> {
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
