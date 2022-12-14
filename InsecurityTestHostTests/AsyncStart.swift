@testable import Insecurity
import UIKit

extension ModalCoordinator {
    struct AsyncMount {
        let onPresentCompleted: Task<Void, Never>
        let onFinish: Task<Result?, Never>
    }
    
    @MainActor
    func asyncMount(on viewController: UIViewController, animated: Bool) async -> AsyncMount {
        var onPresentCompletedCont: CheckedContinuation<Void, Never>?
        var onFinishCont: CheckedContinuation<Result?, Never>?
        
        let onPresentCompletedTask: Task<Void, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onPresentCompletedCont = cont
            }
        }
        
        let onFinishTask: Task<Result?, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onFinishCont = cont
            }
        }
        
        mount(on: viewController, animated: animated, completion: { result in
            if let onFinishCont {
                onFinishCont.resume(returning: result)
            } else {
                assertionFailure()
            }
        }, onPresentCompleted: {
            if let onPresentCompletedCont {
                onPresentCompletedCont.resume(returning: ())
            } else {
                assertionFailure()
            }
        })
        
        return AsyncMount(onPresentCompleted: onPresentCompletedTask, onFinish: onFinishTask)
    }
    
    struct AsyncStart<NewResult> {
        let onPresentCompleted: Task<Void, Never>
        let onFinish: Task<NewResult?, Never>
    }
    
    @MainActor
    func asyncStart<NewResult>(_ coordinator: ModalCoordinator<NewResult>, animated: Bool) async -> AsyncStart<NewResult> {
        
        var onPresentCompletedCont: CheckedContinuation<Void, Never>?
        var onFinishCont: CheckedContinuation<NewResult?, Never>?
        
        let onPresentCompletedTask: Task<Void, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onPresentCompletedCont = cont
            }
        }
        
        let onFinishTask: Task<NewResult?, Never> = Task { @MainActor in
            await withCheckedContinuation { cont in
                onFinishCont = cont
            }
        }
        
        self.start(coordinator, animated: animated, { result in
                if let onFinishCont {
                    onFinishCont.resume(returning: result)
                } else {
                    assertionFailure()
                }
        }, onPresentCompleted: {
            
                if let onPresentCompletedCont {
                    onPresentCompletedCont.resume(returning: ())
                } else {
                    assertionFailure()
                }
        })
        
        return AsyncStart(onPresentCompleted: onPresentCompletedTask, onFinish: onFinishTask)
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
