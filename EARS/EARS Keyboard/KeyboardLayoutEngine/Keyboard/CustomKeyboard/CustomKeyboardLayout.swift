//
//  CustomKeyboardLayout.swift
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


// MARK: - Layout Style
public var CustomKeyboardLayoutStyle = KeyboardLayoutStyle()

// MARK: - Row Style
public var CustomKeyboardRowStyle = KeyboardRowStyle()
public var CustomKeyboardFirstRowStyle = KeyboardRowStyle(topPadding: 10, topPaddingLandscape: 6)

public var CustomKeyboardSecondRowStyle = KeyboardRowStyle(
  leadingPadding: 22,
  leadingPaddingLandscape: 30,
  trailingPadding: 22,
  trailingPaddingLandscape: 30)

public var CustomKeyboardThirdRowStyle = KeyboardRowStyle(
  bottomPadding: 5,
  bottomPaddingLandscape: 4,
  buttonsPadding: 15)

public var CustomKeyboardChildRowStyle = KeyboardRowStyle(
  leadingPadding: 0,
  trailingPadding: 0)

public var CustomKeyboardFourthRowStyle = KeyboardRowStyle(
  topPadding: 5,
  topPaddingLandscape: 4,
  bottomPadding: 4,
  bottomPaddingLandscape: 4)

// MARK: - Button Style
public var CustomKeyboardKeyButtonStyle = KeyboardButtonStyle(keyPopType: .Default)
public var CustomKeyboardLeftKeyButtonStyle = KeyboardButtonStyle(keyPopType: .Left)
public var CustomKeyboardRightKeyButtonStyle = KeyboardButtonStyle(keyPopType: .Right)

public var CustomKeyboardLowercaseKeyButtonStyle = KeyboardButtonStyle(textOffsetY: -2, keyPopType: .Default)
public var CustomKeyboardLowercaseLeftKeyButtonStyle = KeyboardButtonStyle(textOffsetY: -2, keyPopType: .Left)
public var CustomKeyboardLowercaseRightKeyButtonStyle = KeyboardButtonStyle(textOffsetY: -2, keyPopType: .Right)

public var CustomKeyboardSpaceButtonStyle = KeyboardButtonStyle(font: UIFont.systemFont(ofSize: 15))
public var CustomKeyboardBackspaceButtonStyle = KeyboardButtonStyle(
  backgroundColor: KeyboardViewController.offColor,
  imageSize: 20)

public var CustomKeyboardShiftButtonStyle = KeyboardButtonStyle(
  backgroundColor: KeyboardViewController.offColor,
  imageSize: 20)

public var CustomKeyboardGlobeButtonStyle = KeyboardButtonStyle(
  backgroundColor: KeyboardViewController.offColor,
  imageSize: 40)

public var CustomKeyboardSpecialButtonStyle = KeyboardButtonStyle(
  backgroundColor: KeyboardViewController.mainKeys,
  imageSize: 40)

public var CustomKeyboardReturnButtonStyle = KeyboardButtonStyle(
  backgroundColor: KeyboardViewController.offColor,
  font: UIFont.systemFont(ofSize: 15))

public var CustomKeyboardNumbersButtonStyle = KeyboardButtonStyle(
  backgroundColor: KeyboardViewController.offColor,
  font: UIFont.systemFont(ofSize: 15))

// MARK: - Identifier
public enum CustomKeyboardIdentifier: String {
  case Space = "Space"
  case Backspace = "Backspace"
  case Globe = "Globe"
  case Return = "Return"
  case Numbers = "Numbers"
  case Letters = "Letters"
  case Symbols = "Symbols"
  case ShiftOff = "ShiftOff"
  case ShiftOn = "ShiftOn"
  case ShiftOnce = "ShiftOnce"
  case Special = "Special"
}

// MARK: - CustomKeyboardLayout
public class CustomKeyboardLayout {
  public var uppercase: KeyboardLayout
  public var uppercaseToggled: KeyboardLayout
  public var lowercase: KeyboardLayout
  public var numbers: KeyboardLayout
  public var symbols: KeyboardLayout
  public static var popupList: [Int:UIView] = [:]
  
  public init() {
    switch NSLocale.preferredLanguages.first{
    case let str where str!.contains("es"):
      uppercase = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("Q"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("W"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("E"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("R"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("T"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("Y"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("U"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("I"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("O"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("P"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("A"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("S"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("D"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("F"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("G"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("H"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("J"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("K"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("L"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("Ñ"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Image(UIImage(
                  named: "ShiftOnce",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardShiftButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.ShiftOnce.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("Z"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("X"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("C"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("V"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("B"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("N"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("M"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("espacio"),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("intro"),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      uppercaseToggled = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("Q"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("W"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("E"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("R"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("T"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("Y"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("U"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("I"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("O"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("P"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("A"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("S"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("D"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("F"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("G"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("H"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("J"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("K"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("L"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("Ñ"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Image(UIImage(
                  named: "ShiftOn",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardShiftButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.ShiftOn.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("Z"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("X"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("C"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("V"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("B"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("N"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("M"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("espacio"),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("intro"),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      lowercase = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("q"), style: CustomKeyboardLowercaseLeftKeyButtonStyle),
              KeyboardButton(type: .Key("w"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("e"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("r"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("t"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("y"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("u"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("i"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("o"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("p"), style: CustomKeyboardLowercaseRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("a"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("s"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("d"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("f"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("g"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("h"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("j"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("k"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("l"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("ñ"), style: CustomKeyboardLowercaseRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Image(UIImage(
                  named: "ShiftOff",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardShiftButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.ShiftOff.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("z"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("x"), style: CustomKeyboardLowercaseKeyButtonStyle),
                  KeyboardButton(type: .Key("c"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("v"), style: CustomKeyboardLowercaseKeyButtonStyle),
                  KeyboardButton(type: .Key("b"), style: CustomKeyboardLowercaseKeyButtonStyle),
                  KeyboardButton(type: .Key("n"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("m"), style: CustomKeyboardLowercaseKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("espacio"),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("intro"),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      numbers = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("1"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("2"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("3"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("4"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("5"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("6"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("7"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("8"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("9"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("0"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardRowStyle,
            characters: [
              KeyboardButton(type: .Key("-"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("/"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(":"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(";"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("("), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(")"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("$"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("&"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("@"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("\""), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("#+=".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Symbols.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("."), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key(","), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("¿"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("?"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("!"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("'"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("ABC".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Letters.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("espacio"),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("intro"),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      symbols = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("["), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("]"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("{"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("}"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("#"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("%"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("^"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("*"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("+"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("="), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardRowStyle,
            characters: [
              KeyboardButton(type: .Key("_"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("\\"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("|"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("~"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("<"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(">"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("€"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("£"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("¥"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("•"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("."), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key(","), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("¿"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("?"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("!"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("'"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("ABC".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Letters.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("espacio"),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("intro"),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
    default:
      uppercase = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("Q"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("W"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("E"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("R"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("T"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("Y"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("U"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("I"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("O"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("P"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardSecondRowStyle,
            characters: [
              KeyboardButton(type: .Key("A"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("S"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("D"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("F"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("G"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("H"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("J"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("K"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("L"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Image(UIImage(
                  named: "ShiftOnce",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardShiftButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.ShiftOnce.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("Z"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("X"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("C"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("V"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("B"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("N"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("M"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("space".localized()),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("return".localized()),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      uppercaseToggled = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("Q"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("W"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("E"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("R"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("T"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("Y"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("U"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("I"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("O"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("P"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardSecondRowStyle,
            characters: [
              KeyboardButton(type: .Key("A"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("S"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("D"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("F"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("G"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("H"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("J"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("K"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("L"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Image(UIImage(
                  named: "ShiftOn",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardShiftButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.ShiftOn.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("Z"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("X"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("C"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("V"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("B"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("N"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("M"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("space".localized()),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("return".localized()),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      lowercase = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("q"), style: CustomKeyboardLowercaseLeftKeyButtonStyle),
              KeyboardButton(type: .Key("w"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("e"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("r"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("t"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("y"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("u"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("i"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("o"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("p"), style: CustomKeyboardLowercaseRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardSecondRowStyle,
            characters: [
              KeyboardButton(type: .Key("a"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("s"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("d"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
              KeyboardButton(type: .Key("f"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("g"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("h"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("j"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("k"), style: CustomKeyboardLowercaseKeyButtonStyle),
              KeyboardButton(type: .Key("l"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Image(UIImage(
                  named: "ShiftOff",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardShiftButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.ShiftOff.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("z"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("x"), style: CustomKeyboardLowercaseKeyButtonStyle),
                  KeyboardButton(type: .Key("c"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("v"), style: CustomKeyboardLowercaseKeyButtonStyle),
                  KeyboardButton(type: .Key("b"), style: CustomKeyboardLowercaseKeyButtonStyle),
                  KeyboardButton(type: .Key("n"), style: CustomKeyboardSpecialButtonStyle, identifier: CustomKeyboardIdentifier.Special.rawValue),
                  KeyboardButton(type: .Key("m"), style: CustomKeyboardLowercaseKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("space".localized()),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("return".localized()),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      numbers = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("1"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("2"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("3"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("4"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("5"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("6"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("7"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("8"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("9"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("0"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardRowStyle,
            characters: [
              KeyboardButton(type: .Key("-"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("/"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(":"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(";"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("("), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(")"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("$"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("&"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("@"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("\""), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("#+=".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Symbols.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("."), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key(","), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("?"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("!"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("'"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("ABC".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Letters.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("space".localized()),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("return".localized()),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
      
      symbols = KeyboardLayout(
        style: CustomKeyboardLayoutStyle,
        rows: [
          KeyboardRow(
            style: CustomKeyboardFirstRowStyle,
            characters: [
              KeyboardButton(type: .Key("["), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("]"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("{"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("}"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("#"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("%"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("^"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("*"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("+"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("="), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardRowStyle,
            characters: [
              KeyboardButton(type: .Key("_"), style: CustomKeyboardLeftKeyButtonStyle),
              KeyboardButton(type: .Key("\\"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("|"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("~"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("<"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key(">"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("€"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("£"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("¥"), style: CustomKeyboardKeyButtonStyle),
              KeyboardButton(type: .Key("•"), style: CustomKeyboardRightKeyButtonStyle),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardThirdRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("123".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Numbers.rawValue),
              KeyboardRow(
                style: CustomKeyboardChildRowStyle,
                characters: [
                  KeyboardButton(type: .Key("."), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key(","), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("?"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("!"), style: CustomKeyboardKeyButtonStyle),
                  KeyboardButton(type: .Key("'"), style: CustomKeyboardKeyButtonStyle),
                ]
              ),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "Backspace",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardBackspaceButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Backspace.rawValue),
            ]
          ),
          KeyboardRow(
            style: CustomKeyboardFourthRowStyle,
            characters: [
              KeyboardButton(
                type: .Text("ABC".localized()),
                style: CustomKeyboardNumbersButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Letters.rawValue),
              KeyboardButton(
                type: .Image(UIImage(
                  named: "emoji-plus",
                  in: Bundle(for: CustomKeyboard.self),
                  compatibleWith: nil)),
                style: CustomKeyboardGlobeButtonStyle,
                width: .Relative(percent: 0.115),
                identifier: CustomKeyboardIdentifier.Globe.rawValue),
              KeyboardButton(
                type: .Text("space".localized()),
                style: CustomKeyboardSpaceButtonStyle,
                identifier: CustomKeyboardIdentifier.Space.rawValue),
              KeyboardButton(
                type: .Text("return".localized()),
                style: CustomKeyboardReturnButtonStyle,
                width: .Relative(percent: 0.18),
                identifier: CustomKeyboardIdentifier.Return.rawValue),
            ]
          ),
        ]
      )
    }
  }
}
extension String {
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        //If the string is not found, we show **<key>** for debugging.
        return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
    }
}
