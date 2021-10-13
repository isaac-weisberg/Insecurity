import UIKit

public protocol NavigationControllerNavigation: AnyObject {
    func start<NewResult>(_ child: NavigationChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startNew<NewResult>(_ navigationController: UINavigationController,
                             _ child: NavigationChild<NewResult>,
                             animated: Bool,
                             _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ child: ModalChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
