import UIKit

// I loooove private APIs
private let parento = "parent"
private let modale = "Modal"
private let voio = "View"
private let controllero = "Controller"
private let modalParentObservationKeypath = "\(parento)\(modale)\(voio)\(controllero)"

public class ModalHost: ModalNavigation {
    private weak var hostController: UIViewController?
    
    public init(_ hostController: UIViewController) {
        self.hostController = hostController
    }
    
    init(optionalHostController hostController: UIViewController?) {
        self.hostController = hostController
    }
    
    struct NavData {
        enum State {
            case running
            case finished
        }
        
        weak var viewController: UIViewController?
        let coordinator: CommonModalCoordinatorAny
        let state: State
    }
    
    var finalizationDepth: Int = 0
    var navData: [NavData] = []
    private var notKilled: Bool = true
    
    func kill() {
        notKilled = false
        nextHostChild?.kill()
    }
    
    func purge() {
        guard let hostController = hostController else {
            assertionFailure("ModalHost child has finished working, but the root of the ModalHost was long dead, which is bug")
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
        
        
        self.navData = Array(prunedNavData)
        
        if notKilled {
            let controllerToDismissFrom: UIViewController?
            if let topNavData = prunedNavData.last {
                if let topController = topNavData.viewController {
                    if topController.presentedViewController != nil {
                        controllerToDismissFrom = topController
                    } else {
                        controllerToDismissFrom = nil
                    }
                } else {
                    insecPrint("ModalHost child is supposed to dismiss his content, but instead turns out he's dead")
                    controllerToDismissFrom = nil
                }
            } else {
                let hostHasPresentedController = hostController.presentedViewController != nil
                // There used to be an assertion that the host has a presentedViewController, but what I found out recently is that if
                // the view controller is removed from window, the modal chain of relationships between view controllers
                // is broken and presented view controller becomes nil
                // This means only one thing - the batching of change applications is inevitable
                // But for this time, this will have to do
                if hostHasPresentedController {
                    controllerToDismissFrom = hostController
                } else {
                    controllerToDismissFrom = nil
                }
            }
            
            controllerToDismissFrom?.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.enqueuedChildStartRoutine?()
            }
        }
    }
    
    func finalize(_ child: CommonModalCoordinatorAny) {
        let indexOpt = navData.firstIndex { navData in
            navData.coordinator === child
        }
        
        guard let index = indexOpt else {
            assertionFailure("Finalizing non-existing child. Maybe it's too early to call the completion of the coordinator? Or it's a bug...")
            return
        }
        
        let oldNavData = navData[index]
        navData[index] = NavData(viewController: oldNavData.viewController, coordinator: oldNavData.coordinator, state: .finished)
    }
    
    func purgeWithoutDismissing(_ child: CommonModalCoordinatorAny) {
        let indexOpt = navData.firstIndex { navData in
            navData.coordinator === child
        }
        
        guard let index = indexOpt else {
            assertionFailure("Finalizing non-existing child")
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
    
    func dispatch(_ controller: UIViewController, _ animated: Bool, _ child: CommonModalCoordinatorAny) {
        let electedHostControllerOpt: UIViewController?
        if let topNavData = navData.last {
            if let hostController = topNavData.viewController {
                let hostDoesntPresentAnything = hostController.presentedViewController == nil
                if hostDoesntPresentAnything {
                    electedHostControllerOpt = hostController
                } else {
                    assertionFailure("Top controller in the modal stack is already busy presenting something else, which is unexpected...")
                    electedHostControllerOpt = nil
                }
            } else {
                assertionFailure("The top controller of modal stack is somehow dead")
                electedHostControllerOpt = nil
            }
        } else {
            electedHostControllerOpt = self.hostController
        }
        
        guard let electedHostController = electedHostControllerOpt else {
            assertionFailure("No host was found to start a child")
            return
        }
        
        let navData = NavData(viewController: controller, coordinator: child, state: .running)
        self.navData.append(navData)
        electedHostController.present(controller, animated: true, completion: nil)
    }
    
    func startNavigation<CoordinatorType: CommonNavigationCoordinator>(_ navigationController: UINavigationController,
                                                                       _ child: CoordinatorType,
                                                                       animated: Bool,
                                                                       _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        self._startNavigation(navigationController, child, animated: animated) { result in
            completion(result)
        }
    }
    
    func startModal<CoordinatorType: CommonModalCoordinator>(_ child: CoordinatorType,
                                                             animated: Bool,
                                                             _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        _startChild(child, animated: animated) { result in
            completion(result)
        }
    }
    
    private func _startNavigation<CoordinatorType: CommonNavigationCoordinator>(_ navigationController: UINavigationController,
                                                                                _ initialChild: CoordinatorType,
                                                                                animated: Bool,
                                                                                _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        let navigationHost = NavigationHost(navigationController)
        let modalCoordinator = ModalCoordinatorWithNavigationHost<CoordinatorType.Result>(navigationHost, navigationController)
        
        initialChild._updateHostReference(navigationHost)
        
        initialChild._finishImplementation = { [weak modalCoordinator] result in
            if let modalCoordinator = modalCoordinator {
                modalCoordinator.internalFinish(result)
            } else {
                assertionFailure("ModalHost child has called finish way before we could initialize the coordinator or after it has already completed")
            }
        }
        navigationController.setViewControllers([ initialChild.viewController ], animated: Insecurity.navigationControllerRootIsAssignedWithAnimation)
        
        self._startChild(modalCoordinator, animated: animated) { modalCoordinatorResult in
            completion(modalCoordinatorResult)
        }
    }
    
    var enqueuedChildStartRoutine: (() -> Void)?
    
    private func _startChild<CoordinatorType: CommonModalCoordinator>(_ child: CoordinatorType, animated: Bool, _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        if finalizationDepth > 0 {
            // Enqueing the start to happen after batch purge
            enqueuedChildStartRoutine = { [weak self] in
                guard let self = self else { return }
                self.enqueuedChildStartRoutine = nil
                self.startChildImmediately(child, animated: animated, completion)
            }
        } else {
            startChildImmediately(child, animated: animated, completion)
        }
    }
    
    private func startChildImmediately<CoordinatorType: CommonModalCoordinator>(_ child: CoordinatorType,
                                                                                animated: Bool,
                                                                                _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        child._updateHostReference(self)
        
        weak var kvoContext: InsecurityKVOContext?
        weak var weakController: UIViewController?
        child._finishImplementation = { [weak self, weak child] result in
            guard let self = self else {
                assertionFailure("ModalHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = child else { return }
            
            // Clean up
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            
            // Actual work
            self.finalize(child)
            self.finalizationDepth += 1
            if self.notKilled {
                completion(result)
            }
            self.finalizationDepth -= 1
            self.purge()
        }
        let controller = child.viewController
        weakController = controller
        
        kvoContext = controller.insecurityKvo.addHandler(
            UIViewController.self,
            modalParentObservationKeypath
        ) { [weak self, weak child] viewController in
            guard let self = self else {
                assertionFailure("ModalHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = child else { return }

            if viewController == nil {
                if let kvoContext = kvoContext {
                    weakController?.insecurityKvo.removeObserver(kvoContext)
                }

                weakController?.deinitObservable.onDeinit = nil
                self.purgeWithoutDismissing(child)
                completion(nil)
            }
        }
        
        controller.deinitObservable.onDeinit = { [weak self, weak child] in
            guard let self = self, let child = child else { return }
            
            // Actual work
            self.purgeWithoutDismissing(child)
            if self.notKilled {
                completion(nil)
            }
        }
        
        dispatch(controller, animated, child)
    }
    
#if DEBUG
    deinit {
        insecPrint("\(type(of: self)) deinit")
    }
#endif
    
    // MARK: - ModalNavigation
    
    public func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        self.startModal(child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ child: NavigationCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        self.startNavigation(navigationController, child, animated: animated) { result in
            completion(result)
        }
    }
    
    // MARK: - AdaptiveNavigation
    
    public func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>, in context: AdaptiveContext, animated: Bool, _ completion: @escaping (NewResult?) -> Void) {
        switch context._internalContext {
        case .current, .modal:
            startModal(child, animated: animated) { result in
                completion(result)
            }
        case .newNavigation(let navigationController):
            self.startNavigation(navigationController, child, animated: animated) { result in
                completion(result)
            }
        case .currentNavigation(let deferredNavigationController):
            let navigationController = deferredNavigationController.make()
            
            self.startNavigation(navigationController, child, animated: animated) { result in
                completion(result)
            }
        }
    }
    
    var hasChildren: Bool {
        return !navData.isEmpty
    }
    
    public var topContext: AdaptiveNavigation! {
        return nextHostChild?.topContext ?? self
    }
    
    private var nextHostChild: NavigationHost? {
        if let lastNavData = self.navData.last?.coordinator as? ModalCoordinatorWithNavigationHostAny {
            #if DEBUG
            let indicesOfModalChildrenRetainingNavigationHosts = self.navData.enumerated().compactMap { index, navData -> Int? in
                if (navData.coordinator as? ModalCoordinatorWithNavigationHostAny) != nil {
                    return index
                }
                
                return nil
            }
            assert(indicesOfModalChildrenRetainingNavigationHosts.count == 1, "How comes ModalNavigation has 2 children with NavigationHosts inside of them?")
            #endif
            
            if let navigationHostChild = lastNavData.navigationHostChild {
                return navigationHostChild
            }
        }
        
        return nil
    }
}
