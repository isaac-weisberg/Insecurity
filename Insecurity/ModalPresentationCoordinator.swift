import UIKit

public enum ModachildResult<NormalResult> {
    case normal(NormalResult)
    case dismissed
}

public protocol ModarollerCoordinatorAny: AnyObject {
    func startNavitrollerChild<NewResult>(_ navigationController: UINavigationController,
                                          _ child: NavichildCoordinator<NewResult>,
                                          animated: Bool,
                                          _ completion: @escaping (ModachildResult<NewResult>) -> Void)
    
    func startChild<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (ModachildResult<NewResult>) -> Void)
    
    func startOverTop<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (ModachildResult<NewResult>) -> Void)
}

public class ModarollerCoordinator<Result>: ModarollerCoordinatorAny {
    weak var host: UIViewController?
    
    init(_ host: UIViewController) {
        self.host = host
    }
    
    init(optionalHost host: UIViewController?) {
        self.host = host
    }
    
    struct NavData {
        enum State {
            case running
            case finished
        }
        
        weak var viewController: UIViewController?
        let coordinator: ModachildCoordinatorAny
        let state: State
    }
    
    var finalizationDepth: Int = 0
    var navData: [NavData] = []
    
    func purge() {
        guard let host = host else {
            assertionFailure("Modal Coordinator child has finished working, but his presenting parent was long dead, which is bug")
            return
        }
        
        assert(finalizationDepth >= 0, "Weird context closures")
        guard finalizationDepth == 0 else {
            return
        }
        
        let navData = self.navData
        
        if navData.isEmpty {
            assertionFailure("Purge called upon when there are no actual children present")
            return
        }
        
        let inversedNavData = navData
            .makeIterator()
            .reversed()
        
        let prunedNavData = inversedNavData.compactMap { navData -> NavData? in
            switch navData.state {
            case .running:
                return navData
            case .finished:
                return nil
            }
        }
            .reversed()
        
        let controllerToDismissFrom: UIViewController?
        if let topNavData = prunedNavData.last {
            if let topController = topNavData.viewController {
                if topController.presentedViewController != nil {
                    controllerToDismissFrom = topController
                } else {
                    if topController.view.window == nil {
                        // The modal chain has broken because the UIViewController or its parent has been removed from the window
                        // This is expected but only when the finish propagation that happens inside this Modatroller
                        // causes UIWindow to release the modal host AND/OR modal children (assuming they belonged to the same UIWindow)
                        // somewhere up the coordinator chain.
                        //
                        // If presentedViewController is nil for some other reason, then it's a bug
                    } else {
                        assertionFailure("Modal child is supposed to dismiss its presentedViewControler content, but it has Jack Nicholson presented, so it's a bug")
                    }
                    controllerToDismissFrom = nil
                }
            } else {
                print("Modaroller child is supposed to dismiss his content, but instead turns out he's dead")
                controllerToDismissFrom = nil
            }
        } else {
            let hostHasPresentedController = host.presentedViewController != nil
            // There used to be an assertion that the host has a presentedViewController, but what I found out recently is that if
            // the view controller is removed from window, the modal chain of relationships between view controllers
            // is broken and presented view controller becomes nil
            // This means only one thing - the batching of change applications is inevitable
            // But for this time, this will have to do
            if hostHasPresentedController {
                controllerToDismissFrom = host
            } else {
                if host.view.window == nil {
                    // The modal chain has broken because the UIViewController or its parent has been removed from the window
                    // This is expected but only when the finish propagation that happens inside this Modatroller
                    // causes UIWindow to release the modal host AND/OR modal children (assuming they belonged to the same UIWindow)
                    // somewhere up the coordinator chain.
                    //
                    // If presentedViewController is nil for some other reason, then it's a bug
                } else {
                    assertionFailure("Host is supposed to dismiss its presentedViewControler content, but it has Jack Nicholson presented, so it's a bug")
                }
                controllerToDismissFrom = nil
            }
        }
        
        self.navData = Array(prunedNavData)
        
        controllerToDismissFrom?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.enqueuedChildStartRoutine?()
        }
    }
    
    func finalize(_ modachild: ModachildCoordinatorAny) {
        let index = navData.firstIndex { navData in
            navData.coordinator === modachild
        }
        
        guard let index = index else {
            assertionFailure("Finalizing non-existing modachild. Maybe it's too early to call the completion of the coordinator? Or it's a bug...")
            return
        }
        
        let oldNavData = navData[index]
        navData[index] = NavData(viewController: oldNavData.viewController, coordinator: oldNavData.coordinator, state: .finished)
    }
    
    func purgeOnDealloc(_ modachild: ModachildCoordinatorAny) {
        let index = navData.firstIndex { navData in
            navData.coordinator === modachild
        }
        
        guard let index = index else {
            assertionFailure("Finalizing non-existing modachild")
            return
        }
        
        #if DEBUG
        let shouldCheckDeallocationOrder: Bool
        
        if let firstNonDeadNavData = self.navData.first(where: { navData in
            navData.viewController != nil
        }) {
            let viewController = firstNonDeadNavData.viewController!
            shouldCheckDeallocationOrder = viewController.view.window != nil
        } else {
            shouldCheckDeallocationOrder = true
        }
    
        if shouldCheckDeallocationOrder {
            assert(index == self.navData.endIndex - 1, "Dealocation ensued not from the end")
        }
        #endif
        
        var newNavData = self.navData
        newNavData.remove(at: index)
        
        self.navData = newNavData
        
        assert(enqueuedChildStartRoutine == nil, "Child start couldn't ve been enqueued because dealloc purge is called before the result is propagated to the parent")
    }
    
    func dispatch(_ controller: UIViewController, _ animated: Bool, _ modachild: ModachildCoordinatorAny) {
        let electedHost: UIViewController?
        if let topNavData = navData.last {
            if let hostController = topNavData.viewController {
                let hostDoesntPresentAnything = hostController.presentedViewController == nil
                if hostDoesntPresentAnything {
                    electedHost = hostController
                } else {
                    assertionFailure("Top controller in the modal stack is already busy presenting something else, which is unexpected...")
                    electedHost = nil
                }
            } else {
                assertionFailure("The top controller of modal stack is somehow dead")
                electedHost = nil
            }
        } else {
            electedHost = self.host
        }
        
        guard let electedHost = electedHost else {
            assertionFailure("No host was found to start a child")
            return
        }
        
        let navData = NavData(viewController: controller, coordinator: modachild, state: .running)
        self.navData.append(navData)
        electedHost.present(controller, animated: true, completion: nil)
    }
    
    public func startOverTop<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                        animated: Bool,
                                        _ completion: @escaping (ModachildResult<NewResult>) -> Void) {
        startChild(modachild, animated: animated) { result in
            completion(result)
        }
    }
    
    public func startNavitrollerChild<NewResult>(_ navigationController: UINavigationController,
                                                 _ child: NavichildCoordinator<NewResult>,
                                                 animated: Bool,
                                                 _ completion: @escaping (ModachildResult<NewResult>) -> Void) {
        var modachildFinish: ((NewResult) -> Void)?
        let navitrollerCoordinator = NavitrollerCoordinator(navigationController, child) { result in
            if let modachildFinish = modachildFinish {
                modachildFinish(result)
            } else {
                assertionFailure("Navigation Controller child has called finish way before we could initialize the coordinator or after when it has already completed")
            }
        }

        let modachild = ModachildWithNavitroller<NewResult>(navitrollerCoordinator, navigationController)
        modachildFinish = { result in
            modachildFinish = nil
            modachild.finish(result)
        }
        
        self.startChild(modachild, animated: animated) { modarollerResult in
            completion(modarollerResult)
        }
    }
    
    var enqueuedChildStartRoutine: (() -> Void)?
    
    public func startChild<NewResult>(_ modachild: ModachildCoordinator<NewResult>, animated: Bool, _ completion: @escaping (ModachildResult<NewResult>) -> Void) {
        if finalizationDepth > 0 {
            // Enqueing the start to happen after batch purge
            enqueuedChildStartRoutine = { [weak self] in
                guard let self = self else { return }
                self.enqueuedChildStartRoutine = nil
                self.startChildImmediately(modachild, animated: animated, completion)
            }
        } else {
            startChildImmediately(modachild, animated: animated, completion)
        }
    }
    
    func startChildImmediately<NewResult>(_ modachild: ModachildCoordinator<NewResult>, animated: Bool, _ completion: @escaping (ModachildResult<NewResult>) -> Void) {
        
        modachild.modaroller = self
        let controller = modachild.viewController
        weak var weakControler: UIViewController? = controller
        modachild._finishImplementation = { [weak self, weak modachild] result in
            guard let self = self, let modachild = modachild else { return }
            
            assert(weakControler != nil, "Finish called but the controller is long dead")
            weakControler?.onDeinit = nil
            self.finalize(modachild)
            self.finalizationDepth += 1
            completion(.normal(result))
            self.finalizationDepth -= 1
            self.purge()
        }
        
        controller.onDeinit = { [weak self, weak modachild] in
            guard let self = self, let modachild = modachild else { return }
            self.purgeOnDealloc(modachild)
            completion(.dismissed)
        }
        
        dispatch(controller, animated, modachild)
    }
    
#if DEBUG
    deinit {
        print("Modal Presentation Coordinator deinit \(type(of: self))")
    }
#endif
}

protocol ModachildCoordinatorAny: AnyObject {
    
}

open class ModachildCoordinator<Result>: ModachildCoordinatorAny {
    private weak var _modaroller: ModarollerCoordinatorAny?
    
    public var modaroller: ModarollerCoordinatorAny! {
        get {
            assert(_modaroller != nil, "Attempted to use modaroller before the coordinator was started or after it has finished")
            return _modaroller
        }
        set {
            _modaroller = newValue
        }
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((Result) -> Void)?
    
    public func finish(_ result: Result) {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("Finish called before the coordinator was started")
            return
        }
        
        _finishImplementation(result)
    }
    
    public init() {
        
    }
}

class ModachildWithNavitroller<Result>: ModachildCoordinator<Result> {
    let navitrollerChild: NavitrollerCoordinator<Result>?
    weak var _storedViewController: UIViewController?
    
    override var viewController: UIViewController {
        return _storedViewController!
    }
    
    init(_ navitrollerChild: NavitrollerCoordinator<Result>,
         _ _storedViewController: UIViewController?) {
        
        self.navitrollerChild = navitrollerChild
        self._storedViewController = _storedViewController
    }
}
