import UIKit

struct Weak<Value> where Value: AnyObject {
    weak var value: Value?
    
    init(_ value: Value) {
        self.value = value
    }
}

struct InsecurityHostState {
    enum Stage {
        case ready
        case batching
        case purging
    }
    
    var stage: Stage
    var notDead: Bool
}

private enum FinalizationKind {
    case callback
    case kvo
    case deinitialization
}

public class InsecurityHost {
    enum Frame {
        enum State {
            case live
            case finishedByCompletion
            case finishedByKVO
            case finishedByDeinit
        }
        
        struct Regular {
            let state: State
            let coordinator: CommonModalCoordinatorAny
            weak var viewController: UIViewController?
        }
        
        case regular(Regular)
        
        struct Navigation {
            struct Child {
                let state: State
                let coordinator: CommonNavigationCoordinatorAny
                weak var viewController: UIViewController?
            }
            
            weak var navigationController: UINavigationController?
        }
        
        case navigation(Navigation)
    }
    
    var frames: [Frame] = []
    
    enum Root {
        case modal(Weak<UIViewController>)
        case navigation(Weak<UINavigationController>)
    }
    
    let root: Root
    
    var state = InsecurityHostState(stage: .ready, notDead: true)
    
    public init(modal viewController: UIViewController) {
        self.root = .modal(Weak<UIViewController>(viewController))
    }
    
    public init(navigation viewController: UINavigationController) {
        self.root = .navigation(Weak<UINavigationController>(viewController))
    }
    
    var scheduledStartRoutine: (() -> Void)?
    
    // MARK: - Modal
    
    func start<Coordinator: CommonModalCoordinator>(
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        switch state.stage {
        case .ready:
            immediateDispatchModal(child, animated: animated) { result in
                completion(result)
            }
        case .batching:
            if scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self.scheduledStartRoutine = nil
                self.immediateDispatchModal(child, animated: animated) { result in
                    completion(result)
                }
            }
        case .purging:
            assertionFailure("Please don't start during purges")
        }
    }
    
    private func immediateDispatchModal<Coordinator: CommonModalCoordinator>(
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        assert(state.stage == .ready)
        
        child._updateHostReference(self)
        
        weak var weakChild = child
        weak var kvoContext: InsecurityKVOContext?
        weak var weakController: UIViewController?
        
        child._finishImplementation = { [weak self] result in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil
            
            guard let self = self else {
                assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = weakChild else { return }
            
            self.finalizeModal(child, .callback) {
                completion(result)
            }
        }
        
        let controller = child.viewController
        weakController = controller
        
        kvoContext = controller.insecurityKvo.addHandler(
            UIViewController.self,
            modalParentObservationKeypath
        ) { [weak self, weak child] oldController, newController in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil
            
            if oldController != nil, newController == nil {
                guard let self = self else {
                    assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                    return
                }
                guard let child = child else { return }
            
                self.finalizeModal(child, .kvo) {
                    completion(nil)
                }
            }
        }
        
        controller.deinitObservable.onDeinit = { [weak self, weak child] in
            weakChild?._finishImplementation = nil
            
            guard let self = self, let child = child else { return }
            
            self.finalizeModal(child, .deinitialization) {
                completion(nil)
            }
        }
        
        dispatchModal(controller, animated, child)
    }
    
    private func finalizeModal(
        _ child: CommonModalCoordinatorAny,
        _ kind: FinalizationKind,
        _ callback: () -> Void
    ) {
        let indexOfChildOpt = frames.firstIndex(where: { frame in
            switch frame {
            case .regular(let regular):
                return regular.coordinator === child
            case .navigation:
                return false
            }
        })
        
        if let indexOfChild = indexOfChildOpt {
            switch frames[indexOfChild] {
            case .regular(let regular):
                let newState: Frame.State
                
                switch kind {
                case .callback:
                    newState = .finishedByCompletion
                case .kvo:
                    newState = .finishedByKVO
                case .deinitialization:
                    newState = .finishedByDeinit
                }
                
                frames[indexOfChild] = .regular(
                    Frame.Regular(
                        state: newState,
                        coordinator: regular.coordinator,
                        viewController: regular.viewController
                    )
                )
            case .navigation:
                fatalError()
            }
        }
        
        self.state.stage = .batching
        if self.state.notDead {
            callback()
        }
        self.state.stage = .purging
        self.purge()
        self.state.stage = .ready
    }
    
    private func dispatchModal(_ controller: UIViewController, _ animated: Bool, _ child: CommonModalCoordinatorAny) {
        let electedHostControllerOpt: UIViewController?
        if let topFrame = frames.last {
            if let hostController = topFrame.viewController {
                let hostDoesntPresentAnything = hostController.presentedViewController == nil
                if hostDoesntPresentAnything {
                    electedHostControllerOpt = hostController
                } else {
                    assertionFailure("Top controller in the modal stack is already busy presenting something else")
                    electedHostControllerOpt = nil
                }
            } else {
                assertionFailure("Top controller of modal stack is somehow dead")
                electedHostControllerOpt = nil
            }
        } else {
            electedHostControllerOpt = root.viewController
        }
        
        guard let electedHostController = electedHostControllerOpt else {
            assertionFailure("No parent was found to start a child")
            return
        }
        
        let frame = Frame.regular(Frame.Regular(state: .live, coordinator: child, viewController: controller))
        self.frames.append(frame)
        
        electedHostController.present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Navigation Current
    
    
    
    // MARK: - Purge
    
    private func purge() {
        
    }
}

extension InsecurityHost: ModalNavigation {
    public func start<NewResult>(
        _ child: ModalCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
    
    public func start<NewResult>(
        _ navigationController: UINavigationController,
        _ child: NavigationCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
}

extension InsecurityHost: NavigationControllerNavigation {
    public func start<NewResult>(
        _ child: NavigationCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
}

extension InsecurityHost: AdaptiveNavigation {
    public func start<NewResult>(
        _ child: AdaptiveCoordinator<NewResult>,
        in context: AdaptiveContext,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
}

private extension InsecurityHost.Root {
    var viewController: UIViewController? {
        switch self {
        case .navigation(let weak):
            return weak.value
        case .modal(let weak):
            return weak.value
        }
    }
}

private extension InsecurityHost.Frame {
    var viewController: UIViewController? {
        switch self {
        case .regular(let regular):
            return regular.viewController
        case .navigation(let navigation):
            return navigation.navigationController
        }
    }
}
