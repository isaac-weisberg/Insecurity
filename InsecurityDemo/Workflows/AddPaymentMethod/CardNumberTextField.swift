import Foundation

class CardNumberTextField: InsetTextField {
    init() {
        super.init(frame: .zero)
        
        placeholder = "Card Number"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
