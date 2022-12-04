import UIKit

protocol CommonModalCoordinator: AnyObject {
    var isInLiveState: Bool { get }
    
    func parentWillDismiss()
    
    func findFirstAliveAncestorAndCutTheChainDismissing(_ completion: @escaping () -> Void)
}

struct WeakCommonModalCoordinator {
    weak var value: CommonModalCoordinator?
    
    init(_ value: CommonModalCoordinator) {
        self.value = value
    }
}

extension CommonModalCoordinator {
    var weak: WeakCommonModalCoordinator {
        WeakCommonModalCoordinator(self)
    }
}
