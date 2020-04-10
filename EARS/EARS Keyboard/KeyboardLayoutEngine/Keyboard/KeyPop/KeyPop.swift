//
//  KeyPop.swift
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
//import Shadow

// MARK: - KeyPopType
public enum KeyPopType {
  case Default
  case Left
  case Right
}

// MARK: - KeyPopStyle
public struct KeyPopStyle {
  public var backgroundColor: UIColor
  public var shadow: Shadow?
  public var widthMultiplier: CGFloat
  public var heightMultiplier: CGFloat
  public var font: UIFont
  public var textColor: UIColor
  public var contentInset: CGSize
  public var contentOffset: CGSize

  public init(
    backgroundColor: UIColor? = nil,
    shadow: Shadow? = nil,
    widthMultiplier: CGFloat? = nil,
    heightMultiplier: CGFloat? = nil,
    font: UIFont? = nil,
    textColor: UIColor? = nil,
    contentInset: CGSize? = nil,
    contentOffset: CGSize? = nil) {
    self.backgroundColor = backgroundColor ?? #colorLiteral(red: 0.9764705882, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
    self.shadow = shadow ?? nil
    self.widthMultiplier = widthMultiplier ?? 1.2
    self.heightMultiplier = heightMultiplier ?? 1.2
    self.font = font ?? UIFont.systemFont(ofSize: 15)
    self.textColor = textColor ?? KeyboardViewController.textColor
    self.contentInset = contentInset ?? CGSize(width: 5, height: 5)
    self.contentOffset = contentOffset ?? CGSize.zero
  }
}

// MARK: - KeyPop
public class KeyPop: UIView {
  public var type: KeyPopType = .Default
  public var style: KeyPopStyle = KeyPopStyle()
  private(set) var keyboardButton: KeyboardButton?
  private(set) var contentView: UIView?
    @available(iOS 13.0, *)
    var osTheme: UIUserInterfaceStyle {
        return UIScreen.main.traitCollection.userInterfaceStyle
    }
  // MARK: Init
  public init(referenceButton keyboardButton: KeyboardButton, style: KeyPopStyle = KeyPopStyle()) {
    super.init(frame: CGRect.zero)
    self.style = style
    self.keyboardButton = keyboardButton
    isUserInteractionEnabled = false

    switch keyboardButton.type {
    case .Key(let text):
      let label = UILabel()
      label.text = text
      if #available(iOSApplicationExtension 13.0, *) {
      if osTheme == .dark{
        label.textColor = UIColor.black
        }
      }else{
       label.textColor = style.textColor
      }
      label.textAlignment = .center
      label.adjustsFontSizeToFitWidth = true
      label.minimumScaleFactor = 0.5
      if let textLabel = keyboardButton.textLabel {
        label.font = textLabel.font.withSize(textLabel.font.pointSize * style.widthMultiplier)
      } else {
        label.font = style.font.withSize(style.font.pointSize * style.widthMultiplier)
      }
      addSubview(label)
      contentView = label
    case .Text(let text):
      let label = UILabel()
      label.text = text
      label.textColor = style.textColor
      label.textAlignment = .center
      label.adjustsFontSizeToFitWidth = true
      label.minimumScaleFactor = 0.5
      if let textLabel = keyboardButton.textLabel {
        label.font = textLabel.font.withSize(textLabel.font.pointSize * style.widthMultiplier)
      } else {
        label.font = style.font.withSize(style.font.pointSize * style.widthMultiplier)
      }
      contentView = label
      addSubview(label)
    case .Image(let image):
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      imageView.image = image
      contentView = imageView
      addSubview(imageView)
    }
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: Layout
  public override func layoutSubviews() {
    super.layoutSubviews()
    contentView?.frame = CGRect(
      x: style.contentInset.width + style.contentOffset.width,
      y: style.contentInset.height + style.contentOffset.height,
      width: frame.size.width - (style.contentInset.width * 2),
      height: frame.size.height - (style.contentInset.height * 2))
  }
}
