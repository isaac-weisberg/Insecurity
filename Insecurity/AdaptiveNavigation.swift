import UIKit

public enum AdaptiveContext {
    case current
    case newModal
    case new(UINavigationController)
}

public protocol AdaptiveNavigation: AnyObject {
    func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                          in context: AdaptiveContext,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}

public extension AdaptiveNavigation {
    func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        start(child, in: .current, animated: animated) { result in
            completion(result)
        }
    }
    
    func startModal<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        start(child, in: .newModal, animated: animated) { result in
            completion(result)
        }
    }
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: AdaptiveCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        start(child, in: .new(navigationController), animated: animated) { result in
            completion(result)
        }
    }
}
