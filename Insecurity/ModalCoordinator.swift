import UIKit

open class ModalCoordinator<Result>: CommonModalCoordinator {
    private weak var _navigation: (ModalNavigation & AdaptiveNavigation)?
    
    public var navigation: (ModalNavigation & AdaptiveNavigation)! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((Result?) -> Void)?
    
    var _onFinish: ((Result?) -> Void)?
    
    func bindToHost(_ navigation: ModalNavigation & AdaptiveNavigation,
                    _ onFinish: @escaping (Result?, FinalizationKind) -> Void) -> UIViewController {
        self._navigation = navigation
        
        let controller = self.viewController
        
        weak var kvoContext: InsecurityKVOContext?
        weak var weakController: UIViewController?
        
        self._finishImplementation = { [weak self] result in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            self?._finishImplementation = nil
            
            onFinish(nil, .callback)
        }
        
        weakController = controller
        
        kvoContext = controller.insecurityKvo.addHandler(
            UIViewController.self,
            modalParentObservationKeypath
        ) { [weak self] oldController, newController in
            if oldController != nil, newController == nil {
                if let kvoContext = kvoContext {
                    weakController?.insecurityKvo.removeObserver(kvoContext)
                }
                weakController?.deinitObservable.onDeinit = nil
                self?._finishImplementation = nil
                
                onFinish(nil, .kvo)
            }
        }
        
        controller.deinitObservable.onDeinit = { [weak self] in
            assert(weakController == nil)
            
            self?._finishImplementation = nil
            
            onFinish(nil, .deinitialization)
        }
        
        return controller
    }
    
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
    
    func _updateHostReference(_ host: ModalNavigation & AdaptiveNavigation) {
        _navigation = host
    }
    
    public init() {
        
    }
}
