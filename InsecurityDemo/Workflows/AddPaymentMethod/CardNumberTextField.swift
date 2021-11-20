//
//  CardNumberTextField.swift
//  InsecurityDemo
//
//  Created by a.vaysberg on 11/20/21.
//

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
