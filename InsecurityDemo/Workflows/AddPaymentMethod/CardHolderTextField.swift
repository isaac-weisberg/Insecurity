//
//  CardHolderTextField.swift
//  InsecurityDemo
//
//  Created by a.vaysberg on 11/20/21.
//

import Foundation

class CardHolderTextField: InsetTextField {
    init() {
        super.init(frame: .zero)
        
        placeholder = "Card Holder"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
