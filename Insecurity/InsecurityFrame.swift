import UIKit

struct Frame {
    let coordinator: CommonCoordinatorAny
    let controller: Weak<UIViewController>
    let previousController: Weak<UIViewController>
    
    init(
        coordinator: CommonCoordinatorAny,
        controller: UIViewController,
        previousController: UIViewController
    ) {
        self.init(
            coordinator: coordinator,
            controller: Weak(controller),
            previousController: Weak(previousController)
        )
    }
    
    init(
        coordinator: CommonCoordinatorAny,
        controller: Weak<UIViewController>,
        previousController: Weak<UIViewController>
    ) {
        self.coordinator = coordinator
        self.controller = controller
        self.previousController = previousController
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
