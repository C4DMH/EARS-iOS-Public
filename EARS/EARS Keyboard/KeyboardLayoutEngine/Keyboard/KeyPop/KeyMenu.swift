//
//  KeyMenu.swift
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

// MARK: - KeyMenuType
public enum KeyMenuType {
  case Horizontal
  case Vertical
  case Special
}

// MARK: - KeyMenuStyle
public struct KeyMenuStyle {
  // MARK: Shadow
  public var shadow: Shadow?

  // MARK: Background Color
  public var backgroundColor: UIColor

  // MARK: Item Style
  public var itemSize: CGSize

  // MARK: Padding
  public var horizontalMenuItemPadding: CGFloat
  public var horizontalMenuLeftPadding: CGFloat
  public var horizontalMenuRightPadding: CGFloat

  // MARK: Init
  public init(
    shadow: Shadow? = Shadow(),
    backgroundColor: UIColor? = nil,
    itemSize: CGSize? = nil,
    horizontalMenuItemPadding: CGFloat? = nil,
    horizontalMenuLeftPadding: CGFloat? = nil,
    horizontalMenuRightPadding: CGFloat? = nil) {
    self.shadow = shadow
    self.backgroundColor = backgroundColor ?? #colorLiteral(red: 0.9764705882, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
    self.itemSize = itemSize ?? CGSize(width: 40, height: 40)
    self.horizontalMenuItemPadding = horizontalMenuItemPadding ?? 2.5
    self.horizontalMenuLeftPadding = horizontalMenuLeftPadding ?? 5
    self.horizontalMenuRightPadding = horizontalMenuRightPadding ?? 5
  }
}

// MARK: - KeyMenu
public class KeyMenu: UIView {
  public var items = [KeyMenuItem]()
  public var style = KeyMenuStyle()
  public var type = KeyMenuType.Horizontal

  private let titleLabelTag = 1

  public var selectedIndex: Int = -1 {
    didSet {
      if selectedIndex == -1 {
        for item in items {
          item.highlighted = false
        }
      }
      layoutIfNeeded()
    }
  }

  // MARK: Init
  public init(items: [KeyMenuItem], style: KeyMenuStyle, type: KeyMenuType) {
    super.init(frame: CGRect.zero)
    self.items = items
    self.style = style
    self.type = type
    
    backgroundColor = style.backgroundColor
    //applyShadow(shadow: style.shadow)
    
    for item in items {
      addSubview(item)
    }
 
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: Layout
  public override func layoutSubviews() {
    super.layoutSubviews()
    switch type {
    case .Horizontal:
      generateHorizontalMenu()
    case .Vertical:
      generateVerticalMenu()
    case .Special:
      generateSpecialMenu()
    }
  }
    
    var specialWidth: CGFloat = 0
    public static var update = false
    public static var zeroIndex = false
    public static var rightSide = false
    public static var reverseOnce = false
    public static var buttonWidth: CGFloat = 0
    public static var buttonHeight: CGFloat = 0
    
    public func setWidthConst(){
        specialWidth =  KeyMenu.update ? CGFloat(items.count) * KeyMenu.buttonWidth : KeyMenu.buttonWidth - (
            (CGFloat(items.count - 1) * (KeyMenu.buttonWidth / 10) ))
    }
    var customKeyboard:CustomKeyboard!
    public func setCustomKeyboard(keyboard: CustomKeyboard){
        customKeyboard = keyboard
    }
    public func getCustomKeyboard() -> CustomKeyboard{
        return customKeyboard
    }
    public func reverseMenuItems(){
        items.reverse()
    }
    private func generateSpecialMenu() {
        self.backgroundColor = #colorLiteral(red: 0.9764705882, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
        let verticalPadding = (KeyMenu.buttonHeight / 14)
        let paddings = ((KeyMenu.buttonWidth * 1.5) - KeyMenu.buttonWidth) +
            (CGFloat(items.count - 1) * (KeyMenu.buttonWidth / 10))
        
        setWidthConst()
        frame = CGRect(
            x: ((KeyMenu.buttonWidth * 1.5) - KeyMenu.buttonWidth) / 2,
            y: 0,
            width: specialWidth + paddings,
            height: KeyMenu.buttonHeight + verticalPadding)
        
        var currentX = ((KeyMenu.buttonWidth * 1.5) - KeyMenu.buttonWidth) / 2
        for item in items {
            item.frame = CGRect(
                x: currentX,
                y: verticalPadding,
                width: KeyMenu.buttonWidth,
                height: KeyMenu.buttonHeight)
            currentX += item.frame.size.width + (KeyMenu.buttonWidth / 10)
        }
    }

  private func generateHorizontalMenu() {
    let verticalPadding = CGFloat(5)
    let paddings = style.horizontalMenuLeftPadding +
      style.horizontalMenuRightPadding +
      (CGFloat(items.count - 1) * style.horizontalMenuItemPadding)
    let itemsWidth = CGFloat(items.count) * style.itemSize.width
    frame = CGRect(
      x: 0,
      y: 0,
      width: itemsWidth + paddings,
      height: style.itemSize.height + (verticalPadding * 2))

    var currentX = style.horizontalMenuLeftPadding
    for item in items {
      item.frame = CGRect(
        x: currentX,
        y: verticalPadding,
        width: style.itemSize.width,
        height: style.itemSize.height)
      currentX += item.frame.size.width + style.horizontalMenuItemPadding
    }
  }

  private func generateVerticalMenu() {
    frame = CGRect(
      x: 0,
      y: 0,
      width: style.itemSize.width,
      height: CGFloat(items.count) * style.itemSize.height)

    var currentY = CGFloat(0)
    for (index, item) in items.enumerated() {
      if index == items.count - 1 {
        item.separator = nil
      }
      item.frame = CGRect(
        x: 0,
        y: currentY,
        width: style.itemSize.width,
        height: style.itemSize.height)
      currentY += item.frame.size.height
    }
  }

  // MARK: Update Selection
  public func updateSelection(touchLocation location: CGPoint, inView view: UIView) {
    var tempIndex = KeyMenu.zeroIndex ? 0 : -1
    for (index, item) in items.enumerated() {
        item.highlighted = view.convert(item.frame, from: self).contains(location)
      if item.highlighted {
        tempIndex = index
      }
    }
    selectedIndex = tempIndex
  }
}
