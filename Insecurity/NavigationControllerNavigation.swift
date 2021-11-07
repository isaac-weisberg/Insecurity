import UIKit

public protocol NavigationControllerNavigation: AnyObject {
    func start<NewResult>(_ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (NewResult?) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (NewResult?) -> Void)
    
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (NewResult?) -> Void)
}
