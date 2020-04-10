//
//  KeyMenuItem.swift
//  KeyboardLayoutEngine
//
//  Created by Cem Olcay on 05/06/16.
//  Launched under the MIT License.
//
//  The original Github repository is: https://github.com/cemolcay/KeyboardLayoutEngine
//
//  Modified by Wyatt Reed on 3/28/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit

// MARK: KeyMenuItemStyle
public struct KeyMenuItemStyle {
  // MARK: Background Color
  public var highlightedBackgroundColor: UIColor

  // MARK: Text Color
  public var textColor: UIColor
  public var highlightedTextColor: UIColor

  // MARK: Font
  public var font: UIFont
  public var highlightedFont: UIFont

  // MARK: Separator
  public var separatorColor: UIColor
  public var separatorWidth: CGFloat

  // MARK: Init
  public init(
    highlightedBackgroundColor: UIColor? = nil,
    textColor: UIColor? = nil,
    highlightedTextColor: UIColor? = nil,
    font: UIFont? = nil,
    highlightedFont: UIFont? = nil,
    separatorColor: UIColor? = nil,
    separatorWidth: CGFloat? = nil) {
    self.highlightedBackgroundColor = highlightedBackgroundColor ?? KeyboardViewController.offMenuColor
    self.textColor = textColor ?? KeyboardViewController.textColor
    self.highlightedTextColor = highlightedTextColor ?? KeyboardViewController.textColor
    self.font = font ?? UIFont.systemFont(ofSize: 15)
    self.highlightedFont = highlightedFont ?? UIFont.boldSystemFont(ofSize: 15)
    self.separatorColor = separatorColor ?? UIColor.white
    self.separatorWidth = separatorWidth ?? 1
  }
}

// MARK: - KeyMenuItem
public typealias KeyMenuItemAction = (_ keyMenuItem: KeyMenuItem) -> Void

public class KeyMenuItem: UIView {
  public var title: String?
  public var style = KeyMenuItemStyle()
  public var action: KeyMenuItemAction?

  public var highlighted: Bool = false {
    didSet {
      setNeedsLayout()
    }
  }

  public var titleLabel: UILabel?
  public var separator: CALayer?

  // MARK: Init
  public init(
    title: String? = "",
    style: KeyMenuItemStyle = KeyMenuItemStyle(),
    action: KeyMenuItemAction? = nil) {
    super.init(frame: CGRect.zero)
    self.title = title
    self.style = style
    self.action = action

    titleLabel = UILabel()
    titleLabel?.text = title
    titleLabel?.textAlignment = .center
    titleLabel?.adjustsFontSizeToFitWidth = true
    addSubview(titleLabel!)

    separator = CALayer()
    separator?.backgroundColor = style.separatorColor.cgColor
    layer.addSublayer(separator!)
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
    @available(iOS 13.0, *)
    var osTheme: UIUserInterfaceStyle {
        return UIScreen.main.traitCollection.userInterfaceStyle
    }

  // MARK: Layout
  public override func layoutSubviews() {
    super.layoutSubviews()
    titleLabel?.frame = CGRect(
      x: 0,
      y: 0,
      width: frame.size.width,
      height: frame.size.height)

    separator?.frame = CGRect(
      x: 0,
      y: frame.size.height - style.separatorWidth,
      width: frame.size.width,
      height: style.separatorWidth)

    if highlighted {
      titleLabel?.textColor = style.highlightedTextColor
      titleLabel?.font = style.highlightedFont.withSize(style.highlightedFont.pointSize * 1.2)
      titleLabel?.backgroundColor = style.highlightedBackgroundColor
    } else {
        if #available(iOSApplicationExtension 13.0, *) {
        if osTheme == .dark{
            titleLabel?.textColor = UIColor.black
            }
        }else{
            titleLabel?.textColor = style.textColor
        }
      titleLabel?.font = style.font.withSize(style.font.pointSize * 1.2)
        titleLabel?.backgroundColor = UIColor.clear
    }
  }
}
