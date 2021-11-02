import Foundation

extension DispatchQueue {
    func asyncAfter(_ timeInterval: TimeInterval, _ work: @escaping () -> Void) {
        asyncAfter(deadline: .now() + timeInterval) {
            work()
        }
    }
}
