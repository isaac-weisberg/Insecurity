import Foundation

extension DispatchQueue {
    func asyncAfter(_ timeInterval: TimeInterval, _ work: @escaping () -> Void) {
        asyncAfter(deadline: .now() + timeInterval) {
            work()
        }
    }
}

// MARK: - Extensions

@inline(__always) func insecAssert(_ condition: @autoclosure () -> Bool,
                                   _ log: InsecurityLog,
                                   _ file: StaticString = #file,
                                   _ line: UInt = #line) {
#if DEBUG
    assert(condition(), "\(log)", file: file, line: line)
#endif
}

@inline(__always) func insecAssertFail(_ log: InsecurityLog,
                                       _ file: StaticString = #file,
                                       _ line: UInt = #line) {
#if DEBUG
    assertionFailure("\(log)", file: file, line: line)
#endif
}

@inline(__always) func insecFatalError(_ log: InsecurityLog,
                                       _ file: StaticString = #file,
                                       _ line: UInt = #line) -> Never {
    fatalError("\(log)", file: file, line: line)
}

func insecAssumptionFailed(_ assumption: InsecurityAssumption,
                           _ file: StaticString = #file,
                           _ line: UInt = #line) {
    Insecurity.onAssumptionFailedLog?(assumption)
}

extension Optional {
    func insecAssertNotNil(_ file: StaticString = #file,
                           _ line: UInt = #line) -> Optional {
#if DEBUG
        if self == nil {
            insecAssertFail(.expectedThisToNotBeNil)
        }
#endif
        return self
    }
    
    func insecAssumeNotNil(_ file: StaticString = #file,
                           _ line: UInt = #line) -> Optional {
#if DEBUG
        if self == nil {
            insecAssumptionFailed(.assumedThisThingWouldntBeNil)
        }
#endif
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

extension Optional {
    func wrapToArrayOrEmpty() -> [Wrapped] {
        if let self = self {
            return [self]
        }
        return []
    }
}

extension Sequence where Self: RandomAccessCollection & MutableCollection, Index == Int {
    func replacing(_ index: Index, with element: Element) -> Self {
        var array = self
        array[index] = element
        return array
    }
    
    func replacingLast(with element: Element) -> Self {
        replacing(self.count - 1, with: element)
    }
}
