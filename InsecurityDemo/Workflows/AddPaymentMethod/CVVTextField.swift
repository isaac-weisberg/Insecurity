import Foundation

class CVVTextField: InsetTextField {
    init() {
        super.init(frame: .zero)
        
        placeholder = "CVV"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
