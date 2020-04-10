//
//  roundedButton.swift
//  EARS Keyboard
//
//  Created by Wyatt Reed on 11/5/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation

import UIKit

@IBDesignable class roundedButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateCornerRadius()
    }
    
    @IBInspectable var rounded: Bool = false {
        didSet {
            updateCornerRadius()
        }
    }
    
    func updateCornerRadius() {
        layer.cornerRadius = rounded ? frame.size.height * 0.3 : 0
    }
}

