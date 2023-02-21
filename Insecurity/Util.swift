import Foundation

extension DispatchQueue {
    func asyncAfter(_ timeInterval: TimeInterval, _ work: @escaping () -> Void) {
        asyncAfter(deadline: .now() + timeInterval) {
            work()
        }
    }
}

// MARK: - Extensions
extension Optional {
    #if DEBUG
    func assertingNotNil(_ file: StaticString = #file, _ line: UInt = #line) -> Optional {
        assert(self != nil, "\(type(of: Wrapped.self)) died too early")
        return self
    }
    #else
    @inline(__always) func assertingNotNil() -> Optional {
        return self
    }
    #endif
    
    #if DEBUG
    func assertNotNil(_ file: StaticString = #file, _ line: UInt = #line) {
        assert(self != nil, "\(type(of: Wrapped.self)) died too early")
    }
    #else
    @inline(__always) func assertNotNil() {
        
    }
    #endif
}

func insecAssert(_ condition: @autoclosure () -> Bool,
                 _ log: InsecurityLog,
                 _ file: StaticString = #file,
                 _ line: UInt = #line) {
    assert(condition(), "\(log)", file: file, line: line)
}

func insecAssertFail(_ log: InsecurityLog,
                     _ file: StaticString = #file,
                     _ line: UInt = #line) {
    assertionFailure("\(log)", file: file, line: line)
}

func insecFatalError(_ log: InsecurityLog,
                     _ file: StaticString = #file,
                     _ line: UInt = #line) -> Never {
    fatalError("\(log)", file: file, line: line)
}

extension Optional {
    func insecAssertNotNil(_ file: StaticString = #file,
                           _ line: UInt = #line) -> Optional {
        if self == nil {
            insecAssertFail(.expectedThisToNotBeNil)
        }
        return self
    }
}

extension Array {
    func at(_ index: Index) -> Element? {
        if index >= 0, index < count {
            return self[index]
        }
        return nil
    }
}

extension Array {
    func replacing(_ index: Index, with element: Element) -> Array {
        var array = self
        array[index] = element
        return array
    }
    
    func replacingLast(with element: Element) -> Array {
        replacing(self.count - 1, with: element)
    }
}
