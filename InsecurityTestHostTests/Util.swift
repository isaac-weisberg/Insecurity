@testable import Insecurity
import XCTest
import Nimble

extension ModalCoordinator.State {
    func isLive(child: CommonModalCoordinator?) -> Bool {
        switch self {
        case .live(let live):
            return live.child === child
        case .dead, .idle, .liveButStagedForDeath:
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
        case .dead, .idle, .liveButStagedForDeath:
            return false
        }
    }
    
    var isLive: Bool {
        switch self {
        case .live:
            return true
        case .dead, .idle, .liveButStagedForDeath:
            return false
        }
    }
    
    var isStagedForDeath: Bool {
        switch self {
        case .liveButStagedForDeath:
            return true
        case .idle, .dead, .live:
            return false
        }
    }
    
    var isDead: Bool {
        switch self {
        case .dead:
            return true
        case .live, .idle, .liveButStagedForDeath:
            return false
        }
    }
    
    var instantiatedVCIfLive: Weak<UIViewController>? {
        switch self {
        case .live(let live):
            return live.controller
        case .liveButStagedForDeath, .dead, .idle:
            return nil
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

func sleep(_ timeInterval: TimeInterval) async {
    try? await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
}

extension UIViewController {
    @MainActor
    func present(_ viewController: UIViewController, animated: Bool) async {
        await withCheckedContinuation { cont in
            self.present(viewController, animated: animated) {
                cont.resume(returning: ())
            }
        }
    }
    
    @MainActor
    func dismiss(animated: Bool) async {
        await withCheckedContinuation { cont in
            self.dismiss(animated: animated) {
                cont.resume(returning: ())
            }
        }
    }
}

extension Bool {
    var not: Bool {
        !self
    }
    
    func assertTrue(file: String = #file, line: UInt = #line) {
        expect(file: file, line: line, self).to(beTrue())
    }
    
    func assertFalse(file: String = #file, line: UInt = #line) {
        expect(file: file, line: line, self).to(beFalse())
    }
}

func assert(_ expression: Bool, file: StaticString = #file, line: UInt = #line) {
    XCTAssert(expression)
}

func mainTask(_ work: @MainActor @escaping () async -> Void) -> Task<Void, Never> {
    Task { @MainActor in
        await work()
    }
}
