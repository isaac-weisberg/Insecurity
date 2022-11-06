import Foundation

extension DispatchQueue {
    func asyncAfter(_ timeInterval: TimeInterval, _ work: @escaping () -> Void) {
        asyncAfter(deadline: .now() + timeInterval) {
            work()
        }
    }
}

func insecDelay(_ timeInterval: TimeInterval, _ work: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(timeInterval) {
        work()
    }
}

struct Weak<Value> where Value: AnyObject {
    weak var value: Value?
    
    init(_ value: Value) {
        self.value = value
    }
}

extension Array {
    func preLast() -> Element? {
        let prelastIndex = count - 2
        
        if prelastIndex >= 0 {
            return self[prelastIndex]
        }
        return nil
    }
}
