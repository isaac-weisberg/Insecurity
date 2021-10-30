import Foundation
import UIKit

public struct Insecurity {
    public static var defaultWindowTransitionDuration: TimeInterval = 0.3
    public static var defaultWindowTransitionOptions: UIView.AnimationOptions = [.transitionCrossDissolve]
    public static var navigationControllerRootIsAssignedWithAnimation: Bool = true
    public static var loggerMode: InsecurityLoggerMode = .none
    public static var navigationControllerDismissalAnimated: Bool = true
}
