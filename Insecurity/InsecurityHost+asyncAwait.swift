import UIKit

@available(iOS 15.0.0, *)
public extension NavigationControllerNavigation {
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(child, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func start<NewResult>(_ child: NavigationCoordinator<NewResult>,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(child, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(child, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
    
@available(iOS 15.0.0, *)
public extension ModalNavigation {
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(child, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(navigationController, child, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
}

@available(iOS 15.0.0, *)
public extension AdaptiveNavigation {
    func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                          in context: AdaptiveContext,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(child, in: context, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(child, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool) async -> NewResult? {
        
        return await withUnsafeContinuation { continuation in
            self.start(navigationController, child, animated: animated) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
