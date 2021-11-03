import UIKit

open class NewWindowCoordinator {
    public let navigation: NewWindowHost
    
    public init(_ window: UIWindow) {
        self.navigation = NewWindowHost(window)
    }
}
