import UIKit

public enum ModarollerResult<NormalResult> {
    case normal(NormalResult)
    case dismissed
}

public class ModarollerCoordinator {
    let host: UIViewController
    
    public init(_ host: UIViewController) {
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
                controllerToDismissFrom = topController
            } else {
                print("Modaroller child is supposed to dismiss his content, but instead turns out he's dead")
                controllerToDismissFrom = nil
            }
        } else {
            let hostHasPresentedController = host.presentedViewController != nil
            assert(hostHasPresentedController, "Host is supposed to dismiss its content, but it has Jack Nickolson presented, so it's a bug")
            if hostHasPresentedController {
                controllerToDismissFrom = host
            } else {
                controllerToDismissFrom = nil
            }
        }
        
        self.navData = Array(prunedNavData)
        controllerToDismissFrom?.dismiss(animated: true)
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
        
        var newNavData = self.navData
        assert(index == newNavData.endIndex - 1, "Dealocation ensued not from the end")
        newNavData.remove(at: index)
        
        self.navData = newNavData
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
    
    public func startChild<NewResult>(_ modachild: ModachildCoordinator<NewResult>, animated: Bool, _ completion: @escaping (ModarollerResult<NewResult>) -> Void) {
        weak var weakControler: UIViewController?
        let controller = modachild.make(self) { [weak self] result in
            guard let self = self else { return }
            
            assert(weakControler != nil, "Called coordinator finish way before it could be started")
            weakControler?.onDeinit = nil
            self.finalize(modachild)
            self.finalizationDepth += 1
            completion(.normal(result))
            self.finalizationDepth -= 1
            self.purge()
        }
        
        weakControler = controller
        
        controller.onDeinit = { [weak self] in
            guard let self = self else { return }
            self.purgeOnDealloc(modachild)
            completion(.dismissed)
        }
        
        dispatch(controller, animated, modachild)
    }
    
    #if DEBUG
    deinit {
        print("Modal Presentation Coordinator deinit")
    }
    #endif
}

protocol ModachildCoordinatorAny: AnyObject {
    
}

open class ModachildCoordinator<Result>: ModachildCoordinatorAny {
    let make: (ModarollerCoordinator, @escaping (Result) -> Void) -> UIViewController
    
    public init(_ make: @escaping (ModarollerCoordinator, @escaping (Result) -> Void) -> UIViewController) {
        self.make = make
    }
}
