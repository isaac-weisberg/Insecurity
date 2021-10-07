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

extension NavitrollerCoordinator: InsecurityNavigation {
    var navitroller: NavitrollerCoordinator {
        return self
    }
    
    public func start<NewResult>(_ child: InsecurityChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let navitrollerChild = NavichildMagicCoordinator(child)
        
        navitroller.startChild(navitrollerChild, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: InsecurityChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let navitrollerChild = NavichildMagicCoordinator(child)
        
        navitroller.startNewNavitroller(navigationController, navitrollerChild, animated: animated) { result in
            completion(result)
        }
    }
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        
        let modachild = ModachildMagicCoordinator(child)
        navitroller.startModachild(modachild, animated: animated) { result in
            completion(result)
        }
    }
}

extension ModarollerCoordinator: InsecurityNavigation {
    var modaroller: ModarollerCoordinatorAny {
        return self
    }
    
    public func start<NewResult>(_ child: InsecurityChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let modachild = ModachildMagicCoordinator(child)
        
        modaroller.startChild(modachild, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: InsecurityChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let navitrollerChild = NavichildMagicCoordinator(child)
        
        modaroller.startNavitroller(navigationController, navitrollerChild, animated: animated) { result in
            completion(result)
        }
    }
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                                      animated: Bool,
                                      _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        start(child, animated: animated) { result in
            completion(result)
        }
    }
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
        
        let modachild = ModachildMagicCoordinator<NewResult>(child)
        
        self.start(modachild, duration: duration, options: options) { result in
            completion(.normal(result))
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
        
        let navichild = NavichildMagicCoordinator(child)
        
        self.startNavitroller(navigationController, navichild, duration: duration, options: options) { result in
            completion(.normal(result))
        }
    }
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.start(child, animated: animated) { result in
            completion(result)
        }
    }
}
