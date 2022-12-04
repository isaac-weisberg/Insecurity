@testable import Insecurity
import XCTest

extension ModalCoordinator.State {
    func isLive(child: CommonModalCoordinator?) -> Bool {
        switch self {
        case .live(let live):
            return live.child === child
        case .dead, .idle:
            return false
        }
    }
    
    func isLive(hasChild: Bool) -> Bool {
        switch self {
        case .live(let live):
            if hasChild {
                return live.child != nil
            } else {
                return live.child == nil
            }
        case .dead, .idle:
            return false
        }
    }
    
    var isLive: Bool {
        switch self {
        case .live:
            return true
        case .dead, .idle:
            return false
        }
    }
    
    var isDead: Bool {
        switch self {
        case .dead:
            return true
        case .live, .idle:
            return false
        }
    }
}

extension XCTestCase {
    func wait(for expectation: XCTestExpectation, timeout: TimeInterval? = nil) {
        self.wait(for: [expectation], timeout: timeout ?? 5)
    }
}

func create<Object>(count: Int, of objectFactory: () -> Object) -> [Object] {
    return (0..<count).map { _ in
        objectFactory()
    }
}

extension UIViewController {
    var modalChildrenChain: [UIViewController] {
        var children: [UIViewController] = []
        
        var controllerToSearchForAChild = self
        while let childController = controllerToSearchForAChild.presentedViewController {
            children.append(childController)
            controllerToSearchForAChild = childController
        }
        
        return children
    }
}
