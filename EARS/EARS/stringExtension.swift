//
//  stringExtension.swift
//  EARS
//
//  Created by Wyatt Reed on 4/9/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//
//  Credit: https://medium.com/@marcosantadev/app-localization-tips-with-swift-4e9b2d9672c9

import Foundation
import UIKit

final class UILocalizedLabel: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        text = text?.localized()
        accessibilityLabel = text?.localized()
    }
}

final class UILocalizedButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        let title = self.title(for: .normal)?.localized()
        setTitle(title, for: .normal)
        accessibilityLabel = title
    }
}

final class UILocalizedTextField: UITextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        text = text?.localized()
        accessibilityLabel = text?.localized()
    }
}
final class UILocalizedTextView: UITextView {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        text = text?.localized()
        accessibilityLabel = text?.localized()
    }
}

extension String {
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        //If the string is not found, we show **<key>** for debugging.
        return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
    }
}
