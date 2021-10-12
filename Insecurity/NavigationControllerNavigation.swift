import UIKit

public protocol NavigationControllerNavigation: AnyObject {
    func start<NewResult>(_ child: NavigationChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startNew<NewResult>(_ navigationController: UINavigationController,
                             _ child: InsecurityChild<NewResult>,
                             animated: Bool,
                             _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startNew<NewResult>(_ child: InsecurityChild<NewResult>,
                             animated: Bool,
                             _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
