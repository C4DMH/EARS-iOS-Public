//
//  CustomKeyboard.swift
//  KeyboardLayoutEngine
//
//  Created by Cem Olcay on 11/05/16.
//  Launched under the MIT License.
//
//  The original Github repository is: https://github.com/cemolcay/KeyboardLayoutEngine
//
//  Modified by Wyatt Reed on 3/28/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//


import UIKit

// MARK: - CustomKeyboardDelegate
@objc public protocol CustomKeyboardDelegate {
    @objc optional func customKeyboard(customKeyboard: CustomKeyboard, keyboardButtonPressed keyboardButton: KeyboardButton)
    @objc optional func customKeyboard(customKeyboard: CustomKeyboard, keyButtonPressed key: String)
    @objc optional func customKeyboardSpaceButtonPressed(customKeyboard: CustomKeyboard)
    @objc optional func customKeyboardBackspaceButtonPressed(customKeyboard: CustomKeyboard)
    @objc optional func customKeyboardGlobeButtonPressed(customKeyboard: CustomKeyboard)
    @objc optional func customKeyboardReturnButtonPressed(customKeyboard: CustomKeyboard)
}

// MARK: - CustomKeyboard
public class CustomKeyboard: UIView, KeyboardLayoutDelegate {
  public var keyboardLayout = CustomKeyboardLayout()
  public weak var delegate: CustomKeyboardDelegate?
  public static var saveMassDelete = false
  public static var autoDeleteOngoing = false

  // MARK: CustomKeyobardShiftState
  public enum CustomKeyboardShiftState {
    case Once
    case Off
    case On
  }

  // MARK: CustomKeyboardLayoutState
  public enum CustomKeyboardLayoutState {
    case Letters(shiftState: CustomKeyboardShiftState)
    case Numbers
    case Symbols
  }

  public private(set) var keyboardLayoutState: CustomKeyboardLayoutState = .Letters(shiftState: CustomKeyboardShiftState.Once) {
    didSet {
      keyboardLayoutStateDidChange(oldState: oldValue, newState: keyboardLayoutState)
    }
  }

  // MARK: Shift
    public var shiftToggleInterval: TimeInterval = 0.5
    private var shiftToggleTimer: Timer?

  // MARK: Backspace
    public var backspaceDeleteInterval: TimeInterval = 0.1
    public var backspaceAutoDeleteModeInterval: TimeInterval = 0.1
    private var backspaceDeleteTimer: Timer?
    private var backspaceAutoDeleteModeTimer: Timer?
  
  var menuEnabled = false
  // MARK: KeyMenu
  public var keyMenuLocked: Bool = false
    public var keyMenuOpenTimer: Timer?
    public var keyMenuOpenTimeInterval: TimeInterval = 1
  public var keyMenuShowingKeyboardButton: KeyboardButton? {
    didSet {
      oldValue?.showKeyPop(show: false)
      oldValue?.showKeyMenu(show: false)
      KeyMenu.zeroIndex = false
      if keyMenuShowingKeyboardButton?.keyMenu?.type == .Special{
        KeyMenu.update = false
        keyMenuShowingKeyboardButton?.keyMenu?.setWidthConst()
        keyMenuShowingKeyboardButton?.keyMenu?.layoutSubviews()
        keyMenuShowingKeyboardButton?.showKeyMenu(show: true)
      }
      if keyMenuShowingKeyboardButton?.keyMenu?.type == .Vertical{
        KeyMenu.zeroIndex = true
      }
      keyMenuShowingKeyboardButton?.showKeyPop(show: true)

        DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
            if self!.keyMenuShowingKeyboardButton?.keyMenu?.type != .Special{
                self?.getCurrentKeyboardLayout().typingEnabled = self!.keyMenuShowingKeyboardButton == nil && self!.keyMenuLocked == false
            }
        })
    }
  }

  // MARK: Init
  public init() {
    super.init(frame: CGRect.zero)
    defaultInit()
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    defaultInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    defaultInit()
  }

  private func defaultInit() {
    keyboardLayout = CustomKeyboardLayout()
    KeyboardViewController.layoutView = self
    keyboardLayoutStateDidChange(oldState: nil, newState: keyboardLayoutState)
  }
    private var isPortrait: Bool {
        return UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height
    }
    //var heightConstraint: NSLayoutConstraint?
    var prev = ""
    var changeOnce = false
  // MARK: Layout
  public override func layoutSubviews() {
    super.layoutSubviews()
    if isPortrait{
        if prev != "p"{
            changeOnce = true
        }
        prev = "p"
        getCurrentKeyboardLayout().frame = CGRect(
            x: 0,
            y: 40,
            width: frame.size.width,
            height: frame.size.height - 40)
        layFrame = frame
        if changeOnce{
            KeyboardViewController.heightConstraint?.constant = 256
            UIView.animate(withDuration: 0) {
                self.inputView!.layoutIfNeeded()
            }
            changeOnce = false
        }
        
    }else{
        if prev != "l"{
            changeOnce = true
        }
        prev = "l"
        getCurrentKeyboardLayout().frame = CGRect(
            x: 0,
            y: 0,
            width: frame.size.width,
            height: frame.size.height)
        layFrame = frame
        KeyboardViewController.heightConstraint?.constant = 162
        if changeOnce{
            UIView.animate(withDuration: 0) {
                self.inputView!.layoutIfNeeded()
            }
            changeOnce = false
        }
    }

  }
    
    var layFrame:CGRect = CGRect()
    public func getHeight()-> CGFloat{
        return layFrame.size.height
    }
    public func getWidth()-> CGFloat{
        return layFrame.size.width
    }

  // MARK: KeyboardLayout
  public func getKeyboardLayout(ofState state: CustomKeyboardLayoutState) -> KeyboardLayout {
    switch state {
    case .Letters(let shiftState):
      switch shiftState {
      case .Once:
        return keyboardLayout.uppercase
      case .On:
        return keyboardLayout.uppercaseToggled
      case .Off:
        return keyboardLayout.lowercase
      }
    case .Numbers:
      return keyboardLayout.numbers
    case .Symbols:
      return keyboardLayout.symbols
    }
  }

  public func getCurrentKeyboardLayout() -> KeyboardLayout {
    if emojiLink != nil{
        if emojiLink?.keyboardHeight != frame.size.height {
                //print("emoji called")
                emojiLink?.reloadEmojis()
        }
    }
    return getKeyboardLayout(ofState: keyboardLayoutState)
  }

  public func enumerateKeyboardLayouts(enumerate: (KeyboardLayout) -> Void) {
    let layouts = [
      keyboardLayout.uppercase,
      keyboardLayout.uppercaseToggled,
      keyboardLayout.lowercase,
      keyboardLayout.numbers,
      keyboardLayout.symbols,
    ]

    for layout in layouts {
      enumerate(layout)
    }
  }

  public func keyboardLayoutStateDidChange(oldState: CustomKeyboardLayoutState?, newState: CustomKeyboardLayoutState) {
    // Remove old keyboard layout
    if let oldState = oldState {
      let oldKeyboardLayout = getKeyboardLayout(ofState: oldState)
      oldKeyboardLayout.delegate = nil
      oldKeyboardLayout.removeFromSuperview()
      let lostTouch = oldKeyboardLayout.touchRevive()
        if lostTouch.count == 1{
            delegate?.customKeyboard?(customKeyboard: self, keyButtonPressed: lostTouch.lowercased())
        }
      oldKeyboardLayout.clearTouches()

    }

    // Add new keyboard layout
    let newKeyboardLayout = getKeyboardLayout(ofState: newState)
    newKeyboardLayout.delegate = self
    addSubview(newKeyboardLayout)
    setNeedsLayout()
  }
  var emojiLink:KeyboardViewController?
  public func reload() {
    // Remove current
    let currentLayout = getCurrentKeyboardLayout()
    currentLayout.delegate = nil
    currentLayout.removeFromSuperview()
    // Reload layout
    keyboardLayout = CustomKeyboardLayout()
    keyboardLayoutStateDidChange(oldState: nil, newState: keyboardLayoutState)
  }
    var once = true
    func setEmojis(linkedVC:KeyboardViewController){
        emojiLink = linkedVC
    }

  // MARK: Capitalize
  public func switchToLetters(shiftState shift: CustomKeyboardShiftState) {
    keyboardLayoutState = .Letters(shiftState: shift)
  }

  public func capitalize() {
    switchToLetters(shiftState: .Once)
  }
    public func shiftLower() {
        switchToLetters(shiftState: .Off)
    }
    public func shiftLowerUnlessCapsLock() {
        if case CustomKeyboardLayoutState.Letters(let shiftState) = keyboardLayoutState, shiftState == CustomKeyboardShiftState.Once {
            switchToLetters(shiftState: .Off)
        }
    }
    let queue = DispatchQueue.global()
  // MARK: Backspace Auto Delete
  private func startBackspaceAutoDeleteModeTimer() {

                self.backspaceAutoDeleteModeTimer = Timer.scheduledTimer(
                    timeInterval: self.backspaceAutoDeleteModeInterval,
                    target: self,
                    selector: #selector(CustomKeyboard.autoDelete),
                    userInfo: nil,
                    repeats: true)
    }

  private func startBackspaceDeleteTimer() {
    backspaceDeleteTimer = Timer.scheduledTimer(
        timeInterval: backspaceDeleteInterval,
      target: self,
      selector: #selector(CustomKeyboard.autoDelete),
      userInfo: nil,
      repeats: true)
  }

  private func invalidateBackspaceAutoDeleteModeTimer() {
    backspaceAutoDeleteModeTimer?.invalidate()
    backspaceAutoDeleteModeTimer = nil
    if CustomKeyboard.autoDeleteOngoing{
        CustomKeyboard.saveMassDelete = true
        CustomKeyboard.autoDeleteOngoing = false
    }
  }

  private func invalidateBackspaceDeleteTimer() {
    backspaceDeleteTimer?.invalidate()
    backspaceDeleteTimer = nil
  }

    @objc internal func startBackspaceAutoDeleteMode() {
    invalidateBackspaceDeleteTimer()
    startBackspaceDeleteTimer()
  }

    @objc internal func autoDelete() {
        CustomKeyboard.autoDeleteOngoing = true
        delegate?.customKeyboardBackspaceButtonPressed?(customKeyboard: self)
  }

  // MARK: Shift Toggle
  private func startShiftToggleTimer() {
    shiftToggleTimer = Timer.scheduledTimer(
        timeInterval: shiftToggleInterval,
      target: self,
      selector: #selector(CustomKeyboard.invalidateShiftToggleTimer),
      userInfo: nil,
      repeats: false)
  }

    @objc internal func invalidateShiftToggleTimer() {
    shiftToggleTimer?.invalidate()
    shiftToggleTimer = nil
  }

  // MARK: KeyMenu Toggle
  public func startKeyMenuOpenTimer(forKeyboardButton keyboardButton: KeyboardButton) {
    invalidateKeyMenuOpenTimer()
    keyMenuOpenTimer = Timer.scheduledTimer(
      timeInterval: keyMenuOpenTimeInterval,
      target: self,
      selector: #selector(CustomKeyboard.openKeyMenu(timer:)),
      userInfo: keyboardButton,
      repeats: false)
  }

  public func invalidateKeyMenuOpenTimer() {
    keyMenuOpenTimer?.invalidate()
    keyMenuOpenTimer = nil
    keyMenuShowingKeyboardButton = nil
    keyMenuLocked = false
    getCurrentKeyboardLayout().typingEnabled = true
  }

    @objc public func openKeyMenu(timer: Timer) {
        if let userInfo = timer.userInfo, let keyboardButton = userInfo as? KeyboardButton {
            keyMenuShowingKeyboardButton = keyboardButton
        }
        if keyMenuShowingKeyboardButton?.keyMenu?.type == .Special{
            KeyMenu.rightSide = keyMenuShowingKeyboardButton!.isRightSide()
            menuEnabled = true
            KeyMenu.update = true
            KeyMenu.zeroIndex = true
            keyMenuShowingKeyboardButton?.keyMenu?.setWidthConst()
            //keyMenuShowingKeyboardButton?.keyMenu?.subviews[0].subviews[0].frame.origin.x = -1 * (keyMenuShowingKeyboardButton?.keyMenu?.subviews[0].subviews[0].frame.size.width)!
            keyMenuShowingKeyboardButton?.showKeyMenu(show: false)
            if KeyMenu.rightSide{
                keyMenuShowingKeyboardButton?.keyMenu?.reverseMenuItems()
            }
            keyMenuShowingKeyboardButton?.keyMenu?.layoutSubviews()
            keyMenuShowingKeyboardButton?.showKeyMenu(show: true)
            KeyMenu.update = false
            if KeyMenu.rightSide{
                keyMenuShowingKeyboardButton?.keyMenu?.reverseMenuItems()
            }
        }else{
            keyMenuShowingKeyboardButton?.showKeyMenu(show: true)
        }
        KeyMenu.rightSide = false
        getCurrentKeyboardLayout().typingEnabled = keyMenuShowingKeyboardButton == nil && keyMenuLocked == false
  }

  // MARK: KeyboardLayoutDelegate
  public func keyboardLayout(keyboardLayout: KeyboardLayout, didKeyPressStart keyboardButton: KeyboardButton) {
    //print("didKeyPressStart")

    invalidateBackspaceAutoDeleteModeTimer()
    invalidateBackspaceDeleteTimer()
    invalidateKeyMenuOpenTimer()

    // Backspace
    if keyboardButton.identifier == CustomKeyboardIdentifier.Backspace.rawValue {
        startBackspaceAutoDeleteModeTimer()
    }
    
    if keyboardButton.identifier == CustomKeyboardIdentifier.Special.rawValue {
        //print("\(keyboardButton.isRightSide())")
        startKeyMenuOpenTimer(forKeyboardButton: keyboardButton)
    }
    if keyboardButton.identifier == CustomKeyboardIdentifier.Globe.rawValue {
        startKeyMenuOpenTimer(forKeyboardButton: keyboardButton)
    }
    

    // KeyPop and KeyMenu
    if keyboardButton.style.keyPopType != nil {
      keyboardButton.showKeyPop(show: true)
    } else{
        if keyboardButton.keyMenu != nil {
            if let keyId = keyboardButton.identifier, let identifier = CustomKeyboardIdentifier(rawValue: keyId) {
                //print("\(identifier)")
            }
            keyMenuShowingKeyboardButton = keyboardButton
            keyMenuLocked = false
        }
    }
  }

  public func keyboardLayout(keyboardLayout: KeyboardLayout, didKeyPressEnd keyboardButton: KeyboardButton) {
    //print("didKeyPressEnd")

    delegate?.customKeyboard?(customKeyboard: self, keyboardButtonPressed: keyboardButton)

    // If keyboard key is pressed notify no questions asked
    KeyMenu.zeroIndex = false
    if case KeyboardButtonType.Key(let text) = keyboardButton.type {
        
        if !menuEnabled{
            delegate?.customKeyboard?(customKeyboard: self, keyButtonPressed: text)
        }else{
            menuEnabled = false
        }

      // If shift state was CustomKeyboardShiftState.Once then make keyboard layout lowercase
        if case CustomKeyboardLayoutState.Letters(let shiftState) = keyboardLayoutState, shiftState == CustomKeyboardShiftState.Once {
        keyboardLayoutState = CustomKeyboardLayoutState.Letters(shiftState: .Off)
        return
      }
    }

    // Chcek special keyboard buttons
    if let keyId = keyboardButton.identifier, let identifier = CustomKeyboardIdentifier(rawValue: keyId) {
      switch identifier {

      // Notify special keys
      case .Backspace:
        delegate?.customKeyboardBackspaceButtonPressed?(customKeyboard: self)
      case .Space:
        delegate?.customKeyboardSpaceButtonPressed?(customKeyboard: self)
      case .Globe:
        delegate?.customKeyboardGlobeButtonPressed?(customKeyboard: self)
      case .Special:
        delegate?.customKeyboardGlobeButtonPressed?(customKeyboard: self)
      case .Return:
        delegate?.customKeyboardReturnButtonPressed?(customKeyboard: self)

      // Update keyboard layout state
      case .Letters:
        keyboardLayoutState = .Letters(shiftState: .Off)
      case .Numbers:
        keyboardLayoutState = .Numbers
      case .Symbols:
        keyboardLayoutState = .Symbols

      // Update shift state
      case .ShiftOff:
        if shiftToggleTimer == nil {
          keyboardLayoutState = .Letters(shiftState: .Once)
          startShiftToggleTimer()
        } else {
          keyboardLayoutState = .Letters(shiftState: .On)
          invalidateShiftToggleTimer()
        }
      case .ShiftOnce:
        if shiftToggleTimer == nil {
          keyboardLayoutState = .Letters(shiftState: .Off)
          startShiftToggleTimer()
        } else {
          keyboardLayoutState = .Letters(shiftState: .On)
          invalidateShiftToggleTimer()
        }
      case .ShiftOn:
        if shiftToggleTimer == nil {
          keyboardLayoutState = .Letters(shiftState: .Off)
        }
      }
    }
  }

  public func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesBegin touches: Set<UITouch>) {
    // KeyMenu
    if let menu = keyMenuShowingKeyboardButton?.keyMenu, let touch = touches.first {
        menu.updateSelection(touchLocation: touch.location(in: self), inView: self)
    }
  }

  public func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesMove touches: Set<UITouch>) {
    // KeyMenu
    if let menu = keyMenuShowingKeyboardButton?.keyMenu, let touch = touches.first {
        menu.updateSelection(touchLocation: touch.location(in: self), inView: self)
    }
  }

  public func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesEnd touches: Set<UITouch>?)  {
    invalidateBackspaceAutoDeleteModeTimer()
    invalidateBackspaceDeleteTimer()

    // KeyMenu
    if let menu = keyMenuShowingKeyboardButton?.keyMenu, let touch = touches?.first {
        menu.updateSelection(touchLocation: touch.location(in: self), inView: self)
      // select item
      if menu.selectedIndex >= 0 {
        if let item = menu.items[safe: menu.selectedIndex] {
            item.action?(item)
        }
        keyMenuShowingKeyboardButton = nil
        keyMenuLocked = false
      } else {
        if keyMenuLocked {
          keyMenuShowingKeyboardButton = nil
          keyMenuLocked = false
          return
        }
        keyMenuLocked = true
      }
    }
    invalidateKeyMenuOpenTimer()
  }

  public func keyboardLayout(keyboardLayout: KeyboardLayout, didTouchesCancel touches: Set<UITouch>?) {
    invalidateBackspaceAutoDeleteModeTimer()
    invalidateBackspaceDeleteTimer()
    invalidateKeyMenuOpenTimer()

    // KeyMenu
    if let menu = keyMenuShowingKeyboardButton?.keyMenu, let touch = touches?.first {
        menu.updateSelection(touchLocation: touch.location(in: self), inView: self)
      // select item
      if menu.selectedIndex >= 0 {
        if let item = menu.items[safe: menu.selectedIndex] {
            item.action?(item)
        }
        keyMenuShowingKeyboardButton = nil
        keyMenuLocked = false
      } else {
        if keyMenuLocked {
          keyMenuShowingKeyboardButton = nil
          keyMenuLocked = false
          getCurrentKeyboardLayout().typingEnabled = true
          return
        }
        keyMenuLocked = true
      }
    }
  }
    public func backToLetters(){
        keyboardLayoutState = .Letters(shiftState: .Off)
    }
}
