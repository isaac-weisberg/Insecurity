//
//  InsetTextField.swift
//  InsecurityDemo
//
//  Created by a.vaysberg on 11/20/21.
//

import Foundation
import UIKit

class InsetTextField: UITextField {
    var insets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: insets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: insets)
    }
}
