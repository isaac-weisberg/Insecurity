import UIKit

struct Frame {
    let coordinator: CommonCoordinatorAny
    let controller: Weak<UIViewController>
    
    init(
        coordinator: CommonCoordinatorAny,
        controller: UIViewController
    ) {
        self.init(
            coordinator: coordinator,
            controller: Weak(controller)
        )
    }
    
    init(
        coordinator: CommonCoordinatorAny,
        controller: Weak<UIViewController>
    ) {
        self.coordinator = coordinator
        self.controller = controller
    }
}

extension Array where Element == Frame {
    func topIndex() -> CoordinatorIndex? {
        if isEmpty {
            return nil
        }
        let modalIndex = count - 1
        return CoordinatorIndex(modalIndex: modalIndex)
    }
}

extension Sequence where Element == Frame {
    func dismountFromHost() {
        for frame in self {
            frame.coordinator.dismountFromHost()
        }
    }
}
