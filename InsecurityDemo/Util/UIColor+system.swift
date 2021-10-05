import UIKit

extension UIColor {
    static var systemBackgroundCompat: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    static var systemBrownCompat: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBrown
        } else {
            return .brown
        }
    }
    
    static var systemMintCompat: UIColor {
        if #available(iOS 15.0, *) {
            return .systemMint
        } else {
            return UIColor(red: 0, green: 0.8667, blue: 0.7216, alpha: 1.0) // or whatever...
        }
    }
}
