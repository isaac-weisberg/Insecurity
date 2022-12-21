@testable import Insecurity
import UIKit

extension ModalCoordinator {
    struct AsyncMount {
        let onPresentCompleted: Task<Void, Never>
    }
    
    @MainActor
    func asyncMount(on viewController: UIViewController,
                    animated: Bool,
                    _ completion: @escaping (Result?) -> Void) async -> AsyncMount {
        var onPresentCompletedCont: CheckedContinuation<Void, Never>?
        
        let onPresentCompletedTask: Task<Void, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onPresentCompletedCont = cont
            }
        }
        
        mount(on: viewController, animated: animated, completion: { result in
            completion(result)
        }, onPresentCompleted: {
            if let onPresentCompletedCont {
                onPresentCompletedCont.resume(returning: ())
            } else {
                assertionFailure()
            }
        })
        
        return AsyncMount(onPresentCompleted: onPresentCompletedTask)
    }
    
    struct AsyncStart<NewResult> {
        let onPresentCompleted: Task<Void, Never>
    }
    
    @MainActor
    func asyncStart<NewResult>(_ coordinator: ModalCoordinator<NewResult>,
                               animated: Bool,
                               _ completion: @escaping (NewResult?) -> Void) async -> AsyncStart<NewResult> {
        
        var onPresentCompletedCont: CheckedContinuation<Void, Never>?
        
        let onPresentCompletedTask: Task<Void, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onPresentCompletedCont = cont
            }
        }
        
        self.start(coordinator, animated: animated, { result in
            completion(result)
        }, onPresentCompleted: {
            if let onPresentCompletedCont {
                onPresentCompletedCont.resume(returning: ())
            } else {
                assertionFailure()
            }
        })
        
        return AsyncStart(onPresentCompleted: onPresentCompletedTask)
    }
    
    @MainActor
    func dismissChildren(animated: Bool) async -> Task<Void, Never> {
        return mainTask {
            await withCheckedContinuation { cont in
                self.dismissChildren(animated: animated, completion: {
                    cont.resume(returning: ())
                })
            }
        }
    }
}
