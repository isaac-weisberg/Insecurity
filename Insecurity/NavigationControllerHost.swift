import UIKit

public class NavigationHost: NavigationControllerNavigation {
    private weak var navigationController: UINavigationController?
    
    public init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    struct NavData {
        enum State {
            case running
            case finished
        }
        
        weak var viewController: UIViewController?
        let coordinator: CommonNavigationCoordinatorAny
        let state: State
    }
    
    var finalizationDepth: Int = 0
    var navData: [NavData] = []
    
    func purge() {
        guard let navigationController = navigationController else {
            assertionFailure("NavigationHost child has finished work, but the hosting UINavigationController is already dead, which is bug")
            return
        }
        
        assert(finalizationDepth >= 0, "Weird context closures")
        guard finalizationDepth == 0 else {
            return
        }
        
        let navData = self.navData
        // It's a plus-one because the root view controller is not mentioned in the navData and is located at index 0
        assert(navData.count + 1 == navigationController.viewControllers.count, "Unexpected navigation controller stack count")
        let indicesAndDatas = navData
            .enumerated()
            .reversed()
            .compactMap { index, navData -> (Int, NavData)? in
                switch navData.state {
                case .running:
                    return nil
                case .finished:
                    return (index, navData)
                }
            }
        
        var newNavData = navData
        var realViewControllers = navigationController.viewControllers
        
        indicesAndDatas.forEach { index, navData in
            // It's a plus-one because the `realViewControllers` array contains the viewController index 0, which does not appear in the `navData` array
            if let viewController = realViewControllers.at(index + 1) {
                assert(viewController == navData.viewController, "Wrong instance of navigation controller stack member")
                realViewControllers.remove(at: index + 1)
                newNavData.remove(at: index)
            } else {
                assertionFailure("Miscounted view controllers")
            }
        }
        
        self.navData = newNavData
        navigationController.setViewControllers(realViewControllers, animated: true)
    }
    
    func purgeOnDealloc(_ child: CommonNavigationCoordinatorAny) {
        let indexOpt = navData.firstIndex { navData in
            navData.coordinator === child
        }
        
        guard let index = indexOpt else {
            assertionFailure("Finalizing non-existing child")
            return
        }
        
        var newNavData = self.navData
#if DEBUG
        
        let shouldCheckIfDeallocatedIndexIsAtTheEnd: Bool
        
        let thereAreViewControllerWithNoWindow = self.navData.contains { navData in
            if let viewController = navData.viewController {
                return viewController.view.window == nil
            }
            return false
        }
        
        shouldCheckIfDeallocatedIndexIsAtTheEnd = !thereAreViewControllerWithNoWindow
        
        if shouldCheckIfDeallocatedIndexIsAtTheEnd {
            assert(index == newNavData.endIndex - 1, "Dealocation ensued not from the end")
        }
#endif
        
        newNavData.remove(at: index)
        
        self.navData = newNavData
    }
    
    func finalize(_ child: CommonNavigationCoordinatorAny) {
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
    
    func dispatch(_ controller: UIViewController, child: CommonNavigationCoordinatorAny) {
        let navData = NavData(viewController: controller, coordinator: child, state: .running)
        self.navData.append(navData)
    }
    
    // MARK: - Private
    
    private func _startNewNavigation<CoordinatorType: CommonNavigationCoordinator>(_ navigationController: UINavigationController,
                                                                                   _ initialChild: CoordinatorType,
                                                                                   animated: Bool,
                                                                                   _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        let modalHost = self.asModalHost()
        
        modalHost.startNavigation(navigationController, initialChild, animated: animated) { result in
            completion(result)
        }
    }
    
    private func _startNewModal<CoordinatorType: CommonModalCoordinator>(_ child: CoordinatorType,
                                                                         animated: Bool,
                                                                         _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        let modalHost = self.asModalHost()
        
        modalHost.startModal(child, animated: animated) { result in
            completion(result)
        }
    }
    
    private func _startChild<CoordinatorType: CommonNavigationCoordinator>(_ child: CoordinatorType, animated: Bool, _ completion: @escaping (CoordinatorType.Result?) -> Void) {
        guard let navigationController = navigationController else {
            assertionFailure("NavigationHost has attempted to start a child, but the navigation controller has long since died")
            return
        }
        
        child._updateHostReference(self)
        weak var weakController: UIViewController?
        child._finishImplementation = { [weak self, weak child] result in
            guard let self = self else {
                assertionFailure("NavigationHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = child else { return }
            
            weakController?.deinitObservable.onDeinit = nil
            self.finalize(child)
            self.finalizationDepth += 1
            completion(result)
            self.finalizationDepth -= 1
            self.purge()
        }
        let controller = child.viewController
        weakController = controller
        
        controller.deinitObservable.onDeinit = { [weak self, weak child] in
            guard let self = self, let child = child else { return }
            self.purgeOnDealloc(child)
            completion(nil)
        }
        
        dispatch(controller, child: child)
        navigationController.pushViewController(controller, animated: animated)
    }
    
#if DEBUG
    deinit {
        insecPrint("\(type(of: self)) deinit")
    }
#endif
    
    var _modalHost: ModalHost?
    func asModalHost() -> ModalHost {
        if let modalHost = _modalHost {
            return modalHost
        }
        
        let modalHost = ModalHost(optionalHostController: navigationController)
        self._modalHost = modalHost
        
        return modalHost
    }
    
    // MARK: - NavigationControllerNavigation
    
    public func start<NewResult>(_ child: NavigationCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        _startChild(child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ navigationController: UINavigationController,
                                 _ child: NavigationCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        _startNewNavigation(navigationController, child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        _startNewModal(child, animated: animated) { result in
            completion(result)
        }
    }
    
    // MARK: - AdaptiveNavigation
    
    public func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                                 in context: AdaptiveContext,
                                 animated: Bool,
                                 _ completion: @escaping (NewResult?) -> Void) {
        switch context._internalContext {
        case .current, .currentNavigation:
            self._startChild(child, animated: animated) { result in
                completion(result)
            }
        case .modal:
            _startNewModal(child, animated: animated) { result in
                completion(result)
            }
        case .newNavigation(let navigationController):
            _startNewNavigation(navigationController, child, animated: animated) { result in
                completion(result)
            }
        }
    }
    
    public var topContext: AdaptiveNavigation! {
        if let modalHost = _modalHost, modalHost.hasChildren {
            return modalHost.topContext
        }
        
        return self
    }
}

extension Array {
    func at(_ index: Index) -> Element? {
        if index >= 0, index < count {
            return self[index]
        }
        return nil
    }
}
