import UIKit

final public class NavigationRootCoordinator<Result>: ModalCoordinator<Result> {
    let navigationCoordinator: NavigationCoordinator<Result>
    let navigationControllerFactory: () -> UINavigationController
    
    public init(_ navigationCoordinator: NavigationCoordinator<Result>,
                _ navigationControllerFactory: @escaping () -> UINavigationController) {
        self.navigationCoordinator = navigationCoordinator
        self.navigationControllerFactory = navigationControllerFactory
        
        super.init()
    }
    
    override public var viewController: UIViewController {
        navigationControllerFactory()
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
    
    override func mountOnControllerInternal(on parentViewController: UIViewController,
                                            animated: Bool,
                                            completion: @escaping (Result?) -> Void,
                                            onPresentCompleted: (() -> Void)?) {
        let navigationController = self.navigationControllerFactory()
        
        mountOnCtrlForCtrl(
            on: parentViewController,
            controller: navigationController,
            completion: { result in
                completion(result)
            })
        
        
        navigationCoordinator.mountOnNavigationCoontroller(on: navigationController,
                                                           modalCoordinator: self.weak,
                                                           completion: { result in
            completion(result)
        })
        
        parentViewController.present(navigationController, animated: animated, completion: {
            onPresentCompleted?()
        })
    }
    
    override func mount(on parent: CommonModalCoordinator,
                        completion: @escaping (Result?) -> Void) -> UIViewController {
        let navigationController = super.mount(on: parent, completion: { result in
            completion(result)
        }) as! UINavigationController
        
        navigationCoordinator.mountOnNavigationCoontroller(
            on: navigationController,
            modalCoordinator: self.weak,
            completion: { result in
                completion(result)
            })
        
        return navigationController
    }
}

public extension NavigationCoordinator {
    func root(_ navigationControllerFactory: @autoclosure @escaping () -> UINavigationController) -> NavigationRootCoordinator<Result> {
        NavigationRootCoordinator(self, navigationControllerFactory)
    }
}
