import UIKit
import Nimble
@testable import Insecurity

func awaitAnims() async {
    try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
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
