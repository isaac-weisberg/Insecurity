import UIKit

enum _AdaptiveContext {
    case current
    case modal
    case newNavigation(UINavigationController)
    case currentNavigation(Deferred<UINavigationController>)
}

public struct AdaptiveContext {
    public static var current: AdaptiveContext {
        return AdaptiveContext(.current)
    }
    
    public static var modal: AdaptiveContext {
        return AdaptiveContext(.modal)
    }
    
    public static func navigation(new navigationController: UINavigationController) -> AdaptiveContext {
        return AdaptiveContext(.newNavigation(navigationController))
    }
    
    public static func navigation(fallback navigationController: @autoclosure @escaping () -> UINavigationController) -> AdaptiveContext {
        let defferred = Deferred(navigationController)
        return AdaptiveContext(.currentNavigation(defferred))
    }
    
    static func navigationFallback(_ navigationController: @escaping () -> UINavigationController) -> AdaptiveContext {
        let defferred = Deferred(navigationController)
        return AdaptiveContext(.currentNavigation(defferred))
    }
    
    let _internalContext: _AdaptiveContext
    
    init(_ ctx: _AdaptiveContext) {
        self._internalContext = ctx
    }
}

public protocol AdaptiveNavigation: AnyObject {
    func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                          in context: AdaptiveContext,
                          animated: Bool,
                          _ completion: @escaping (NewResult?) -> Void)
    
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (NewResult?) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (NewResult?) -> Void)
}
