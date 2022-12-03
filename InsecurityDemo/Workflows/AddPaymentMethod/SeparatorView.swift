import Foundation
import UIKit

class SeparatorView: UIView {
    init(){
        super.init(frame: .zero)
        
        backgroundColor = UIColor(white: 0.5, alpha: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
