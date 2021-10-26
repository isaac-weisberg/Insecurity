import Dispatch
import Foundation

extension DispatchQueue {
    func asyncAfter(_ timeInterval: TimeInterval, _ work: @escaping () -> Void) {
        self.asyncAfter(deadline: .now() + timeInterval) {
            work()
        }
    }
}
