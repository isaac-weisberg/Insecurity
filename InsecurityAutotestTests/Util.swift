import UIKit
import Nimble
@testable import Insecurity

func awaitAnims() async {
    try? await Task.sleep(nanoseconds: UInt64(2.5 * (1_000_000_000 as Double)))
}

func awaitAnimsShort() async {
    try? await Task.sleep(nanoseconds: UInt64(0.5 * (1_000_000_000 as Double)))
}

extension UIViewController {
    var modalChain: [UIViewController] {
        var chain: [UIViewController] = []
        
        var parentToSearchForChildOn: UIViewController? = self
        
        while let parent = parentToSearchForChildOn {
            if let child = parent.presentedViewController {
                chain.append(child)
                parentToSearchForChildOn = child
            } else {
                parentToSearchForChildOn = nil
            }
        }
        
        return chain
    }
    
    func dismissAndAwait() async {
        dismiss(animated: true)
        
        await awaitAnims()
    }

    func dismissProm() -> Prom<Void> {
        Prom { res in
            self.dismiss(animated: true, completion: {
                res(())
            })
        }
    }
}

extension ModalCoordinator {
    var instantiatedVC: UIViewController? {
        switch self.state {
        case .mounted(let mounted):
            return mounted.controller.value
        case .dead, .unmounted:
            return nil
        }
    }
}

enum Type1 {
    
}


enum Type2 {
    
}


enum Type3 {
    
}

enum Type4 {
    
}

enum Type5 {
    
}
