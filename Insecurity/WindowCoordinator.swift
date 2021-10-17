import UIKit

open class WindowCoordinator {
    public let navigation: WindowHost
    
    public init(_ window: UIWindow) {
        self.navigation = WindowHost(window)
    }
}
