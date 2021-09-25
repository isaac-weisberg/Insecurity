import UIKit

public enum NavichildResult<NormalResult> {
    case normal(NormalResult)
    case dismissed
}

open class NavitrollerCoordinator {
    let navigationController: UINavigationController
    
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
        assert(finalizationDepth >= 0, "Weird context closures")
        guard finalizationDepth == 0 else {
            return
        }
        
        let navData = self.navData
        assert(navData.count == navigationController.viewControllers.count, "Unexpected navigation controller stack count")
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
            if let viewController = realViewControllers.at(index) {
                assert(viewController == navData.viewController, "Wrong instance of navigation controller stack member")
                realViewControllers.remove(at: index)
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
        assert(index == newNavData.endIndex - 1, "Dealocation ensued not from the end")
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
    
    public func startChild<Result>(_ navichild: NavichildCoordinator<Result>, animated: Bool, _ completion: @escaping (NavichildResult<Result>) -> Void) {
        weak var weakControler: UIViewController?
        let controller = navichild.make(self) { [weak self] result in
            guard let self = self else { return }
            weakControler?.onDeinit = nil
            self.finalize(navichild)
            self.finalizationDepth += 1
            completion(.normal(result))
            self.finalizationDepth -= 1
            self.purge()
        }
        weakControler = controller
        
        controller.onDeinit = { [weak self] in
            guard let self = self else { return }
            self.purgeOnDealloc(navichild)
            completion(.dismissed)
        }
        
        dispatch(controller, navichild: navichild)
        navigationController.pushViewController(controller, animated: animated)
    }
}

protocol NavichildCoordinatorAny: AnyObject {
    
}

open class NavichildCoordinator<Result>: NavichildCoordinatorAny {
    let make: (NavitrollerCoordinator, @escaping (Result) -> Void) -> UIViewController
    
    public init(_ make: @escaping (NavitrollerCoordinator, @escaping (Result) -> Void) -> UIViewController) {
        self.make = make
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
