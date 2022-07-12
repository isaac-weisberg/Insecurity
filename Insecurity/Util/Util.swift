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
