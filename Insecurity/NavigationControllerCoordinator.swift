import UIKit

public protocol NavigationCoordinatorAny: InsecurityNavigation {
    func startChild<NewResult>(_ child: InsecurityChild<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startNewNavigation<NewResult>(_ navigationController: UINavigationController,
                                       _ initialChild: InsecurityChild<NewResult>,
                                       animated: Bool,
                                       _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startOverTop<NewResult>(_ child: InsecurityChild<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}

public class NavigationCoordinator: NavigationCoordinatorAny {
    weak var navigationController: UINavigationController?
    
    public init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
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
        guard let navigationController = navigationController else {
            assertionFailure("Navigation Coordinator child has finished work, but the hosting UINavigationController is already dead, which is bug")
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
    
    func purgeOnDealloc(_ child: InsecurityChildAny) {
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
    
    func dispatch(_ controller: UIViewController, child: InsecurityChildAny) {
        let navData = NavData(viewController: controller, coordinator: child, state: .running)
        self.navData.append(navData)
    }
    
    public func startChild<NewResult>(_ child: InsecurityChild<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        guard let navigationController = navigationController else {
            assertionFailure("Navigation Coordinator has attempted to start a child, but the navigation controller has long since died")
            return
        }
        
        child._navigation = self
        weak var weakController: UIViewController?
        child._finishImplementation = { [weak self, weak child] (result: NewResult) in
            guard let self = self else {
                assertionFailure("NavigationCoordinator wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = child else { return }
            
            weakController?.onDeinit = nil
            self.finalize(child)
            self.finalizationDepth += 1
            completion(.normal(result))
            self.finalizationDepth -= 1
            self.purge()
        }
        let controller = child.viewController
        weakController = controller
        
        controller.onDeinit = { [weak self, weak child] in
            guard let self = self, let child = child else { return }
            self.purgeOnDealloc(child)
            completion(.dismissed)
        }
        
        dispatch(controller, child: child)
        navigationController.pushViewController(controller, animated: animated)
    }
    
    public func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                                      animated: Bool,
                                      _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let modalCoordinator = self.asModalCoordinator()
        
        modalCoordinator.startChild(child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func startNewNavigation<NewResult>(_ navigationController: UINavigationController,
                                              _ initialChild: InsecurityChild<NewResult>,
                                              animated: Bool,
                                              _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let modalCoordinator = self.asModalCoordinator()
        
        modalCoordinator.startNavigation(navigationController, initialChild, animated: animated) { result in
            completion(result)
        }
    }
    
#if DEBUG
    deinit {
        print("Navigation Controller Coordinator deinit \(type(of: self))")
    }
#endif
    
    var _modalCoordinator: ModalCoordinator?
    func asModalCoordinator() -> ModalCoordinator {
        if let modalCoordinator = _modalCoordinator {
            return modalCoordinator
        }
        
        let modalCoordinator = ModalCoordinator(optionalHost: navigationController)
        self._modalCoordinator = modalCoordinator
        
        return modalCoordinator
    }
    
    public func startOverTop<NewResult>(_ child: InsecurityChild<NewResult>,
                                        animated: Bool,
                                        _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let modalCoordinator = self.asModalCoordinator()
        
        modalCoordinator.startOverTop(child, animated: animated) { result in
            completion(result)
        }
    }
    
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
        self.startNewNavigation(navigationController, child, animated: animated) { result in
            completion(result)
        }
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
