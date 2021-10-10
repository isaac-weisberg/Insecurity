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

extension WindowCoordinator: InsecurityNavigation {
    public func start<NewResult>(_ child: InsecurityChild<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
        
        self.start(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController, _ child: InsecurityChild<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let duration: TimeInterval?
        let options: UIView.AnimationOptions?
        if animated {
            duration = Insecurity.defaultWindowTransitionDuration
            options = Insecurity.defaultWindowTransitionOptions
        } else {
            duration = nil
            options = nil
        }
        
        self.start(navigationController, child, duration: duration, options: options) { result in
            completion(result)
        }
    }
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.start(child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ child: InsecurityChild<NewResult>,
                                 duration: TimeInterval?,
                                 options: UIView.AnimationOptions?,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.startModal(child, duration: duration, options: options) { result in
            completion(.normal(result))
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ child: InsecurityChild<NewResult>,
                                 duration: TimeInterval?,
                                 options: UIView.AnimationOptions?,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.startNavigation(navigationController, child, duration: duration, options: options) { result in
            completion(.normal(result))
        }
    }
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                                      duration: TimeInterval?,
                                      options: UIView.AnimationOptions?,
                                      _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.start(child, duration: duration, options: options) { result in
            completion(result)
        }
    }
}
