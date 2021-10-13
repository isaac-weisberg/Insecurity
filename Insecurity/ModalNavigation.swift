import UIKit

public protocol ModalNavigation: AnyObject {
    func start<NewResult>(_ child: ModalChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                             _ child: NavigationChild<NewResult>,
                             animated: Bool,
                             _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
