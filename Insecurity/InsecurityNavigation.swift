import UIKit

public protocol InsecurityNavigation: AnyObject {
    func start<NewResult>(_ child: InsecurityChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: InsecurityChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
