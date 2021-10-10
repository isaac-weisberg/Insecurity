import UIKit

public protocol ModalCoordinatorAny: InsecurityNavigation {
    func startNavigation<NewResult>(_ navigationController: UINavigationController,
                                     _ child: InsecurityChild<NewResult>,
                                     animated: Bool,
                                     _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startChild<NewResult>(_ child: InsecurityChild<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startOverTop<NewResult>(_ child: InsecurityChild<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}

public class ModalCoordinator: ModalCoordinatorAny {
    weak var host: UIViewController?
    
    public init(_ host: UIViewController) {
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
        let coordinator: InsecurityChildAny
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
                print("ModalCoordinator child is supposed to dismiss his content, but instead turns out he's dead")
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
    
    func finalize(_ child: InsecurityChildAny) {
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
    
    func purgeOnDealloc(_ child: InsecurityChildAny) {
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
    
    func dispatch(_ controller: UIViewController, _ animated: Bool, _ child: InsecurityChildAny) {
        let electedHostOpt: UIViewController?
        if let topNavData = navData.last {
            if let hostController = topNavData.viewController {
                let hostDoesntPresentAnything = hostController.presentedViewController == nil
                if hostDoesntPresentAnything {
                    electedHostOpt = hostController
                } else {
                    assertionFailure("Top controller in the modal stack is already busy presenting something else, which is unexpected...")
                    electedHostOpt = nil
                }
            } else {
                assertionFailure("The top controller of modal stack is somehow dead")
                electedHostOpt = nil
            }
        } else {
            electedHostOpt = self.host
        }
        
        guard let electedHost = electedHostOpt else {
            assertionFailure("No host was found to start a child")
            return
        }
        
        let navData = NavData(viewController: controller, coordinator: child, state: .running)
        self.navData.append(navData)
        electedHost.present(controller, animated: true, completion: nil)
    }
    
    public func startOverTop<NewResult>(_ child: InsecurityChild<NewResult>,
                                        animated: Bool,
                                        _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        startChild(child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func startNavigation<NewResult>(_ navigationController: UINavigationController,
                                            _ initialChild: InsecurityChild<NewResult>,
                                            animated: Bool,
                                            _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let navigationCoordinator = NavigationCoordinator(navigationController)
        let navigationChild = InsecurityChildWithNavigationCoordinator<NewResult>(navigationCoordinator, navigationController)
        
        initialChild._navigation = navigationCoordinator
        initialChild._finishImplementation = { [weak navigationChild] result in
            if let navigationChild = navigationChild {
                navigationChild.finish(result)
            } else {
                assertionFailure("NavigationCoordinator child has called finish way before we could initialize the coordinator or after it has already completed")
            }
        }
        navigationController.setViewControllers([ initialChild.viewController ], animated: Insecurity.navigationControllerRootIsAssignedWithAnimation)
        
        self.startChild(navigationChild, animated: animated) { modalCoordinatorResult in
            completion(modalCoordinatorResult)
        }
    }
    
    var enqueuedChildStartRoutine: (() -> Void)?
    
    public func startChild<NewResult>(_ child: InsecurityChild<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
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
    
    func startChildImmediately<NewResult>(_ child: InsecurityChild<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        
        child._navigation = self
        var weakControllerInitialized = false
        weak var weakController: UIViewController?
        child._finishImplementation = { [weak self, weak child] result in
            guard let self = self else {
                assertionFailure("ModalCoordinator wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = child else { return }
            
#if DEBUG
            if weakControllerInitialized {
                assert(weakController != nil, "Finish called but the controller is long dead")
            } else {
                assertionFailure("Finish called way before we could start the coordinator")
            }
#endif
            weakController?.onDeinit = nil
            self.finalize(child)
            self.finalizationDepth += 1
            completion(.normal(result))
            self.finalizationDepth -= 1
            self.purge()
        }
        let controller = child.viewController
        weakController = controller
        weakControllerInitialized = true
        
        controller.onDeinit = { [weak self, weak child] in
            guard let self = self, let child = child else { return }
            self.purgeOnDealloc(child)
            completion(.dismissed)
        }
        
        dispatch(controller, animated, child)
    }
    
#if DEBUG
    deinit {
        print("Modal Presentation Coordinator deinit \(type(of: self))")
    }
#endif
    
    // MARK: - InsecurityNavigation
    
    public func start<NewResult>(_ child: InsecurityChild<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.startChild(child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ child: InsecurityChild<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.startNavigation(navigationController, child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                                      animated: Bool,
                                      _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        self.startChild(child, animated: animated) { result in
            completion(result)
        }
    }
}
