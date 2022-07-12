import UIKit

open class NavigationCoordinator<Result>: CommonNavigationCoordinator {
    private var _navigation: (NavigationControllerNavigation & AdaptiveNavigation)?
    
    public var navigation: (NavigationControllerNavigation & AdaptiveNavigation)! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((Result?) -> Void)?
    
    public func finish(_ result: Result) {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("`finish` called before the coordinator was started")
            return
        }
        
        _finishImplementation(result)
    }
    
    public func dismiss() {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("`dismiss` called before the coordinator was started")
            return
        }
        
        _finishImplementation(nil)
    }
    
    func bindToHost(_ navigation: NavigationControllerNavigation & AdaptiveNavigation,
                    _ onFinish: @escaping (Result?, FinalizationKind) -> Void) -> UIViewController {
        
        self._navigation = navigation
        
        let controller = self.viewController
        weak var weakController: UIViewController? = controller
        
        self._finishImplementation = { [weak self] result in
            weakController?.deinitObservable.onDeinit = nil
            
            guard let self = self else { return }
            self._finishImplementation = nil
            
            onFinish(result, .callback)
        }
        
        controller.deinitObservable.onDeinit = { [weak self] in
            guard let self = self else { return }
            self._finishImplementation = nil
            
            onFinish(nil, .deinitialization)
        }
        
        return controller
    }
    
    public init() {
        
    }
}
