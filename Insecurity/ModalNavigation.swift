import UIKit

public protocol ModalNavigation: AnyObject {
    func start<NewResult>(_ child: ModalChild<NewResult>,
                          animated: Bool,
                          _ completion: (CoordinatorResult<NewResult>) -> Void)
    
    func startNew<NewResult>(_ navigationController: UINavigationController,
                             _ child: InsecurityChild<NewResult>,
                             animated: Bool,
                             _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
