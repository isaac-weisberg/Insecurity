import UIKit

extension UIColor {
    static var systemBackgroundCompat: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    static var systemTealCompat: UIColor {
        if #available(iOS 13.0, *) {
            return .systemTeal
        } else {
            return UIColor(red: 0, green: 0.502, blue: 0.502, alpha: 1.0)
        }
    }
    
    static var systemIndigoCompat: UIColor {
        if #available(iOS 13.0, *) {
            return .systemIndigo
        } else {
            return UIColor(red: 0.2941, green: 0, blue: 0.5098, alpha: 1.0)
        }
    }
    
    static var labelCompat: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }
}
