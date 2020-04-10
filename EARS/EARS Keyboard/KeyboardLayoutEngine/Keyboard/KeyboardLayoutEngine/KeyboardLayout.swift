//
//  KeyboardLayout.swift
//  KeyboardLayoutEngine
//
//  Created by Cem Olcay on 06/05/16.
//  Launched under the MIT License.
//
//  The original Github repository is: https://github.com/cemolcay/KeyboardLayoutEngine
//
//  Modified by Wyatt Reed on 3/28/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit

// MARK: - Array Extension
extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - UITouch Extension
internal extension UITouch {
  internal var key: String {
    return "\(ObjectIdentifier(self))"
  }
}


// MARK: - KeyboardButtonTouch
internal class KeyboardButtonTouch {
  internal var touch: String
  internal var button: KeyboardButton

  internal init(touch: UITouch, button: KeyboardButton) {
    self.touch = touch.key
    self.button = button
  }
}

// MARK: - KeyboardLayoutDelegate
@objc public protocol KeyboardLayoutDelegate {
  // Key Press Events
    @objc optional func keyboardLayout(keyboardLayout: KeyboardLayout, didKeyPressStart keyboardButton: KeyboardButton)
    @objc optional func keyboardLayout(keyboardLayout: KeyboardLayout, didKeyPressEnd keyboardButton: KeyboardButton)
    @objc optional func keyboardLayout(keyboardLayout: KeyboardLayout, didDraggedInFrom oldKeyboardButton: KeyboardButton, to newKeyboardButton: KeyboardButton)
  // Touch Events
    @objc optional func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesBegin touches: Set<UITouch>)
    @objc optional func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesMove touches: Set<UITouch>)
    @objc optional func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesEnd touches: Set<UITouch>?)
    @objc optional func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesCancel touches: Set<UITouch>?)
}

// MARK: - KeyboardLayoutStyle
public struct KeyboardLayoutStyle {
  public var backgroundColor: UIColor

  public init(backgroundColor: UIColor? = nil) {
    self.backgroundColor = backgroundColor ?? UIColor.clear
  }
}

// MARK: - KeyboardLayout
public class KeyboardLayout: UIView {
  public var style: KeyboardLayoutStyle!
  public var rows: [KeyboardRow]!
  public static var keyPopList: [UIView] = []

  public weak var delegate: KeyboardLayoutDelegate?

  private var isPortrait: Bool {
    return UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height
  }

  public var typingEnabled: Bool = true
  private var currentTouches: [KeyboardButtonTouch] = []

  // MARK: Init
  public init(style: KeyboardLayoutStyle, rows: [KeyboardRow]) {
    super.init(frame: CGRect.zero)
    self.style = style
    self.rows = rows

    for row in rows {
      addSubview(row)
    }
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: Layout
  public override func layoutSubviews() {
    super.layoutSubviews()
    superview?.backgroundColor = style.backgroundColor

    let optimumRowHeight = getOptimumRowHeight()
    var currentY: CGFloat = 0
    for row in rows {
      row.isPortrait = isPortrait
      currentY += isPortrait ? row.style.topPadding : row.style.topPaddingLandscape
      row.frame = CGRect(
        x: 0,
        y: currentY,
        width: frame.size.width,
        height: optimumRowHeight)
      currentY += optimumRowHeight + (isPortrait ? row.style.bottomPadding : row.style.bottomPaddingLandscape)
    }
  }

  private func getRowPaddings() -> CGFloat {
    var total = CGFloat(0)
    for row in rows {
      total += isPortrait ? row.style.topPadding + row.style.bottomPadding : row.style.topPaddingLandscape + row.style.bottomPaddingLandscape
    }
    return total
  }

  private func getOptimumRowHeight() -> CGFloat {
    let height = frame.size.height
    let totalPaddings = getRowPaddings()
    return max(0, (height - totalPaddings) / CGFloat(rows.count))
  }

  // MARK: Manage Buttons
  public func getKeyboardButton(atRowIndex rowIndex: Int, buttonIndex: Int) -> KeyboardButton? {
    if let row = rows[safe: rowIndex], let button = row.characters[safe: buttonIndex] as? KeyboardButton {
      let divider = row.characters.count / 2
      if buttonIndex + 1 > divider{
        button.setSide(bool: true)
      }
      return button
    }
    return nil
  }
    public func getSubKeyboardButton(atRowIndex rowIndex: Int, subindex: Int, buttonIndex: Int) -> KeyboardButton? {
        if let row = rows[safe: rowIndex], let subRow = row.characters[safe: subindex] as? KeyboardRow,  let button = subRow.characters[safe: buttonIndex] as? KeyboardButton{
            let divider = subRow.characters.count / 2
            if buttonIndex + 1 > divider{
                button.setSide(bool: true)
            }
            return button
        }
        return nil
    }

  public func getKeyboardButton(withIdentifier identifier: String) -> KeyboardButton? {
    for row in rows {
      for button in row.characters {
        if let button = button as? KeyboardButton, button.identifier == identifier {
          return button
        }
      }
    }
    return nil
  }

  public func addKeyboardButton(keyboardButton button: KeyboardButton, rowAtIndex: Int, buttonIndex: Int?) {
    if let row = rows[safe: rowAtIndex] {
        if let index = buttonIndex, buttonIndex! < row.characters.count {
            row.characters.insert(button, at: index)
      } else {
        row.characters.append(button)
      }
      row.addSubview(button)
    }
  }

  public func removeKeyboardButton(atRowIndex rowIndex: Int, buttonIndex: Int) -> Bool {
    if let row = rows[safe: rowIndex], let button = row.characters[safe: buttonIndex] {
      row.characters.remove(at: buttonIndex)
      button.removeFromSuperview()
      return true
    }
    return false
  }

  // MARK: Touch Handling
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.keyboardLayout?(keyboardLayout: self, didTouchesBegin: touches)
        
        if !typingEnabled {
            return
        }

    // Add valid touches that hit a `KeyboardButton` to `currentTouches` dictionary
    for touch in touches {
        if let button = hitTest(touch.location(in: self), with: nil) as? KeyboardButton {
        if currentTouches.map({ $0.touch }).contains(touch.key) == false {
          currentTouches.append(KeyboardButtonTouch(touch: touch, button: button))
        }
      }
    }

    // Send key press start and end events ordered from current touches
        for (index, currentTouch) in currentTouches.enumerated() {
      if index == max(0, currentTouches.count - 1) {
        delegate?.keyboardLayout?(keyboardLayout: self, didKeyPressStart: currentTouch.button)
        if currentTouch.button.keyMenu?.type == .Special{
            currentTouch.button.showKeyMenu(show: true)
        }
        currentTouch.button.showKeyPop(show: true)
        //self.typingEnabled = true
        
      } else {
        delegate?.keyboardLayout?(keyboardLayout: self, didKeyPressEnd: currentTouch.button)
        if currentTouch.button.keyMenu?.type == .Special{
            currentTouch.button.showKeyMenu(show: false)
        }
        currentTouch.button.showKeyPop(show: false)
        //self.typingEnabled = true
      }
    }

    if currentTouches.count > 1 {
      currentTouches.removeSubrange(0..<max(0, currentTouches.count - 1))
      //currentTouches.removeRange(0..<max(0, currentTouches.count - 1))
    }
  }
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        delegate?.keyboardLayout?(keyboardLayout: self, didTouchesMove: touches)
        
        if !typingEnabled {
            return
        }
        
        for touch in touches {
            if let currentTouch = currentTouches.filter({ $0.touch == touch.key }).first,
                let button = hitTest(touch.location(in: self), with: nil) as? KeyboardButton {
                if currentTouch.button != button {
                    delegate?.keyboardLayout?(keyboardLayout: self, didDraggedInFrom: currentTouch.button, to: button)
                    if button.keyMenu?.type == .Special{
                        currentTouch.button.showKeyMenu(show: false)
                        currentTouch.button.showKeyPop(show: false)
                        currentTouch.button = button
                        KeyMenu.update = false
                        currentTouch.button.keyMenu?.setWidthConst()
                        currentTouch.button.keyMenu?.layoutSubviews()
                        currentTouch.button.showKeyMenu(show: true)
                        //currentTouch.button.keyMenu?.updateSelection(touchLocation: touch.location(in: self), inView: (currentTouch.button.keyMenu?.getCustomKeyboard())!)
                        currentTouch.button.keyMenu?.getCustomKeyboard().startKeyMenuOpenTimer(forKeyboardButton: currentTouch.button)
                    }else{
                        if currentTouch.button.keyMenu?.type == .Special{
                            currentTouch.button.keyMenu?.getCustomKeyboard().invalidateKeyMenuOpenTimer()
                        }
                        self.typingEnabled = true
                        if currentTouch.button.keyMenu?.type == .Special{
                            currentTouch.button.showKeyMenu(show: false)
                        }
                    }
                    currentTouch.button.showKeyPop(show: false)
                    currentTouch.button = button
                    currentTouch.button.showKeyPop(show: true)
                }
            }
        }
    }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    delegate?.keyboardLayout?(keyboardLayout: self, didTouchesEnd: touches)

    if !typingEnabled {
      return
    }
    
    for touch in touches {
      if let currentTouch = currentTouches.filter({ $0.touch == touch.key }).first {
        if currentTouch.button.keyMenu?.type == .Special{
            currentTouch.button.showKeyMenu(show: false)
        }
        currentTouch.button.showKeyPop(show: false)
        delegate?.keyboardLayout?(keyboardLayout: self, didKeyPressEnd: currentTouch.button)
        currentTouches = currentTouches.filter({ $0.touch != touch.key })
      }
    }
  }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    currentTouches.forEach({ $0.button.showKeyPop(show: false) })
    currentTouches.forEach({ $0.button.showKeyMenu(show: false) })
    currentTouches = []
        delegate?.keyboardLayout?(keyboardLayout: self, didTouchesCancel: touches)
  }
    public func clearTouches(){
        currentTouches = []
    }
    public func getTouchCount()-> Int{
        return currentTouches.count
    }
    public func touchRevive()->String{
        if currentTouches.count > 1{
            if case KeyboardButtonType.Key(let text) = currentTouches[1].button.type {
                return text
            }
        }
        return ""
    }
}
