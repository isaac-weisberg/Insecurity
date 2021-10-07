import UIKit

internal let navigationControllerRootIsAssignedWithAnimation = true

public protocol NavitrollerCoordinatorAny: AnyObject {
    func startChild<NewResult>(_ navichild: NavichildCoordinator<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startModachild<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                   animated: Bool,
                                   _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startNewNavitroller<NewResult>(_ navigationController: UINavigationController,
                                               _ initialChild: NavichildCoordinator<NewResult>,
                                               animated: Bool,
                                               _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func startOverTop<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                 animated: Bool,
                                 _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}

public extension NavitrollerCoordinatorAny {
    func start<NewResult>(_ navichild: NavichildCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        startChild(navichild, animated: animated) { result in
            completion(result)
        }
    }
    
    func start<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        startModachild(modachild, animated: animated) { result in
            completion(result)
        }
    }
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ initialChild: NavichildCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        startNewNavitroller(navigationController, initialChild, animated: animated) { result in
            completion(result)
        }
    }
}

open class NavitrollerCoordinator: NavitrollerCoordinatorAny {
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
        let coordinator: NavichildCoordinatorAny
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
    
    func purgeOnDealloc(_ navichild: NavichildCoordinatorAny) {
        let index = navData.firstIndex { navData in
            navData.coordinator === navichild
        }
        
        guard let index = index else {
            assertionFailure("Finalizing non-existing navichild")
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
    
    func finalize(_ navichild: NavichildCoordinatorAny) {
        let index = navData.firstIndex { navData in
            navData.coordinator === navichild
        }
        
        guard let index = index else {
            assertionFailure("Finalizing non-existing navichild. Maybe it's too early to call the completion of the coordinator? Or it's a bug...")
            return
        }
 
        let oldNavData = navData[index]
        navData[index] = NavData(viewController: oldNavData.viewController, coordinator: oldNavData.coordinator, state: .finished)
    }
    
    func dispatch(_ controller: UIViewController, navichild: NavichildCoordinatorAny) {
        let navData = NavData(viewController: controller, coordinator: navichild, state: .running)
        self.navData.append(navData)
    }
    
    public func startChild<NewResult>(_ navichild: NavichildCoordinator<NewResult>, animated: Bool, _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        guard let navigationController = navigationController else {
            assertionFailure("Navigation Coordinator has attempted to start a child, but the navigation controller has long since died")
            return
        }
        
        navichild._navitroller = self
        var weakControllerInitialized = false
        weak var weakController: UIViewController?
        navichild._finishImplementation = { [weak self, weak navichild] (result: NewResult) in
            guard let self = self else {
                assertionFailure("NavitrollerCoordinator wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let navichild = navichild else { return }
            
            #if DEBUG
            if weakControllerInitialized {
                assert(weakController != nil, "Finish called but the controller is long dead")
            } else {
                assertionFailure("Finish called way before we could start the coordinator")
            }
            #endif
            weakController?.onDeinit = nil
            self.finalize(navichild)
            self.finalizationDepth += 1
            completion(.normal(result))
            self.finalizationDepth -= 1
            self.purge()
        }
        let controller = navichild.viewController
        weakController = controller
        weakControllerInitialized = true
        
        controller.onDeinit = { [weak self, weak navichild] in
            guard let self = self, let navichild = navichild else { return }
            self.purgeOnDealloc(navichild)
            completion(.dismissed)
        }
        
        dispatch(controller, navichild: navichild)
        navigationController.pushViewController(controller, animated: animated)
    }
    
    public func startModachild<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                          animated: Bool,
                                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let modaroller = self.asModarollerCoordinator()
        
        modaroller.startChild(modachild, animated: animated) { result in
            completion(result)
        }
    }
    
    public func startNewNavitroller<NewResult>(_ navigationController: UINavigationController,
                                                      _ initialChild: NavichildCoordinator<NewResult>,
                                                      animated: Bool,
                                                      _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let modaroller = self.asModarollerCoordinator()

        modaroller.startNavitroller(navigationController, initialChild, animated: animated) { result in
            completion(result)
        }
    }
    
    #if DEBUG
    deinit {
        print("Navigation Controller Coordinator deinit \(type(of: self))")
    }
    #endif
    
    var modaroller: ModarollerCoordinator?
    func asModarollerCoordinator() -> ModarollerCoordinator {
        if let modaroller = modaroller {
            return modaroller
        }
        
        let modaroller = ModarollerCoordinator(optionalHost: navigationController)
        self.modaroller = modaroller
        
        return modaroller
    }
    
    public func startOverTop<NewResult>(_ modachild: ModachildCoordinator<NewResult>,
                                        animated: Bool,
                                        _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        let modaroller = self.asModarollerCoordinator()
        
        modaroller.startOverTop(modachild, animated: animated) { result in
            completion(result)
        }
    }
}

protocol NavichildCoordinatorAny: AnyObject {
    
}

open class NavichildCoordinator<Result>: NavichildCoordinatorAny {
    weak var _navitroller: NavitrollerCoordinatorAny?
    
    public var navitroller: NavitrollerCoordinatorAny! {
        assert(_navitroller != nil, "Attempted to use navitroller before the coordinator was started or after it has finished")
        return _navitroller
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

class NavichildMagicCoordinator<Result>: NavichildCoordinator<Result> {
    let child: InsecurityChild<Result>
    
    override var viewController: UIViewController {
        child.viewController
    }
    
    init(_ child: InsecurityChild<Result>) {
        self.child = child
        super.init()
        self._finishImplementation = child._finishImplementation
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
