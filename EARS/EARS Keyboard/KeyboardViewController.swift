//
//  KeyboardViewController.swift
//  EARS Keyboard
//
//  Created by Wyatt Reed on 3/13/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//


import UIKit
import Foundation
import CoreData

//import KeyboardLayoutEngine

class KeyboardViewController: UIInputViewController, CustomKeyboardDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    var hostBundleID = ""
    var studyName = ""
    var userDefaults:UserDefaults?
    var stopSpellCheck = false
    var openAccessEnabled = false
    var timer: Timer?
    var popupFrame: UIView = UIView()
    var emoji_bar = UIView()
    var emojiBarLabel = UILabel()
    var autoCorrectEnabled = true
    var globeButtons: [KeyboardButton?]?
    
    static var device_id = ""
    static var keyboardFrame: CGRect = CGRect()
    static var caps = false
    static var capsLock = false
    static var pressed = false
    static var keyInput:KeyboardInputManager?
    static var segmentHeight: CGFloat?
    static var heightConstraint: NSLayoutConstraint?
    
    let characterset = CharacterSet(charactersIn: "0123456789-/:;()$&@\".,?!'[]{}#%^*+=_\\|~<>€£¥•")
    private var keyboardFetchedResultsController: NSFetchedResultsController<KeyboardEntity>!
    
    static var textColor: UIColor         = #colorLiteral(red: 0.03529411765, green: 0.1568627451, blue: 0.3607843137, alpha: 1)
    static var offMenuColor: UIColor      = #colorLiteral(red: 0.5375460386, green: 0.709213078, blue: 0.9995551705, alpha: 1)
    static var offColorButtonBar: UIColor = #colorLiteral(red: 0.7960784314, green: 0.8549019608, blue: 0.9490196078, alpha: 1)
    static var offColor: UIColor          = #colorLiteral(red: 0.7960784314, green: 0.8549019608, blue: 0.9490196078, alpha: 1)
    static var backgroundColor: UIColor   = #colorLiteral(red: 0.8117368817, green: 0.8235126138, blue: 0.8508359194, alpha: 1)
    static var mainKeys: UIColor          = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let parentViewController = self.parent {
            hostBundleID = parentViewController.value(forKey: "_hostBundleID") as! String
        }
        KeyboardViewController.heightConstraint = NSLayoutConstraint(item:self.inputView, attribute:.height, relatedBy:.equal, toItem:nil, attribute:.notAnAttribute, multiplier:0, constant:256)
        KeyboardViewController.heightConstraint!.priority = UILayoutPriority(rawValue: 999)
        KeyboardViewController.heightConstraint!.isActive = true
        self.inputView!.addConstraint(KeyboardViewController.heightConstraint!)
        
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        toggleSuggestionBar()
    }
    override func viewDidAppear(_ animated: Bool) {
        //print("\(customKeyboard.getHeight())")
        keyboardHeight = customKeyboard.getHeight()
        rowWidth = customKeyboard.getWidth()
        rowHeight = keyboardHeight * 0.16
        rowSpaceing = keyboardHeight * 0.09
        self.setupEmojiScrollView(parentView: self.view)
        
    }
    
    public func reloadEmojis(){
        middleView.removeFromSuperview()
        emojiStaticButtonView.removeFromSuperview()
        //print("\(customKeyboard.getHeight())")
        keyboardHeight = customKeyboard.getHeight()
        rowWidth = customKeyboard.getWidth()
        rowHeight = keyboardHeight * 0.16
        rowSpaceing = keyboardHeight * 0.09
        self.setupEmojiScrollView(parentView: self.view)
        if openAccessEnabled && allowSuggestions{
            self.setupSuggestionBar()
        }
    }
    
    @available(iOS 13.0, *)
    var osTheme: UIUserInterfaceStyle {
        return UIScreen.main.traitCollection.userInterfaceStyle
    }

    var preferredLanguage = ""
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOSApplicationExtension 13.0, *) {
            if osTheme == .dark{
                KeyboardViewController.textColor         = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                KeyboardViewController.offMenuColor      = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                KeyboardViewController.offColorButtonBar = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                KeyboardViewController.offColor         = #colorLiteral(red: 0.231372549, green: 0.2274509804, blue: 0.2274509804, alpha: 1)
                KeyboardViewController.backgroundColor  = #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1019607843, alpha: 1)
                KeyboardViewController.mainKeys         = #colorLiteral(red: 0.3764705882, green: 0.3764705882, blue: 0.3764705882, alpha: 1)
            }
        }
        
        keyboardFetchedResultsController = EarsKeyboardService.shared.getFrequentlyUsed()
        let setupValuesIndexPath:IndexPath = NSIndexPath(row: 0, section: 0) as IndexPath
        keyboardFetchedResultsController.delegate = self
        frequentlyUsed = keyboardFetchedResultsController.object(at: setupValuesIndexPath).frequentlyUsed!
        peopleModifierDict = keyboardFetchedResultsController.object(at: setupValuesIndexPath).peopleModifierDict!
        autoCorrectEnabled = keyboardFetchedResultsController.object(at: setupValuesIndexPath).autoCorrectEnabled
        let tempDeviceID = keyboardFetchedResultsController.object(at: setupValuesIndexPath).deviceID
        if tempDeviceID != nil{
            KeyboardViewController.device_id = tempDeviceID!
        }else{
            EarsKeyboardService.shared.setDeviceID(newValue: UIDevice.current.identifierForVendor!.uuidString)
            KeyboardViewController.device_id = UIDevice.current.identifierForVendor!.uuidString
        }
        //print("\(KeyboardViewController.device_id)")
        //Swahili is not a UITextChecker approved language.
        if NSLocale.preferredLanguages.first!.contains("sw"){
            preferredLanguage = "en_US"
        }else{
            preferredLanguage = NSLocale.preferredLanguages.first!
        }
        
        if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height{
            allowSuggestions = true
        }
        
        self.view.backgroundColor = KeyboardViewController.backgroundColor
        //self.view.backgroundColor = #colorLiteral(red: 0.8117368817, green: 0.8235126138, blue: 0.8508359194, alpha: 1)
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        rowWidth = UIScreen.main.bounds.width
        
        if isOpenAccessGranted(){
            openAccessEnabled = isOpenAccessGranted()
            if openAccessEnabled{
                KeyboardViewController.keyInput = KeyboardInputManager()
                
            }
        }
        
        setupKeyboard()
        
    }
    
    private func setupKeyboard() {
        customKeyboard = CustomKeyboard()
        customKeyboard.setEmojis(linkedVC: self)
        self.setupEmojiScrollView(parentView: self.view)
        customKeyboard.delegate = self
        customKeyboard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customKeyboard)
        
        // Autolayout
        if #available(iOSApplicationExtension 9.0, *) {
            customKeyboard.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            customKeyboard.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            customKeyboard.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            customKeyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        } else {
            // Fallback on earlier versions
        }
        
        if #available(iOSApplicationExtension 12.1, *) {
            emojiDictionary = emojisV11
            emojiDictionary["Frequently Used"] = frequentlyUsed
        }else{
            emojiDictionary = emojiV5
            emojiDictionary["Frequently Used"] = frequentlyUsed
        }
        
        
        // menu
        globeButtons = [
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 3, buttonIndex: 1),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 3, buttonIndex: 1),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 3, buttonIndex: 1),
            customKeyboard.keyboardLayout.numbers.getKeyboardButton(atRowIndex: 3, buttonIndex: 1),
            customKeyboard.keyboardLayout.symbols.getKeyboardButton(atRowIndex: 3, buttonIndex: 1),
        ]
        
        let menuItemStyle =  KeyMenuItemStyle(
            separatorColor: UIColor(red: 210.0/255.0, green: 213.0/255.0, blue: 219.0/255.0, alpha: 1),
            separatorWidth: 0.5)
        let autoCorrectString = autoCorrectEnabled ? "Disable Autocorrect" : "Enable Autocorrect"
        
        for globeButton in globeButtons! {
            let menu = KeyMenu(
                items: [
                    KeyMenuItem(title: "Emojis", style: menuItemStyle, action: { _ in self.emojiKeyboard() }),
                    KeyMenuItem(title: "Switch Keyboard", style: menuItemStyle, action: { _ in self.advanceToNextInputMode() }),
                    KeyMenuItem(title: autoCorrectString, style: menuItemStyle, action: { _ in self.autoCorrectToggle() }),
                ],
                style: KeyMenuStyle(backgroundColor: KeyboardViewController.mainKeys, itemSize: CGSize(width: 150, height: 40)),
                type: .Vertical)
            globeButton?.keyMenu = menu
        }
        
        
        let specialButtons = [
            //e
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 2),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 0, buttonIndex: 2),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 2),
            //y
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 5),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 0, buttonIndex: 5),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 5),
            //u
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 6),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 0, buttonIndex: 6),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 6),
            //i
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 7),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 0, buttonIndex: 7),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 7),
            //o
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 8),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 0, buttonIndex: 8),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 0, buttonIndex: 8),
            
            //a
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 0),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 1, buttonIndex: 0),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 0),
            //s
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 1),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 1, buttonIndex: 1),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 1),
            //d
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 2),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 1, buttonIndex: 2),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 2),
            //l
            customKeyboard.keyboardLayout.uppercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 8),
            customKeyboard.keyboardLayout.uppercaseToggled.getKeyboardButton(atRowIndex: 1, buttonIndex: 8),
            customKeyboard.keyboardLayout.lowercase.getKeyboardButton(atRowIndex: 1, buttonIndex: 8),
            
            //z
            customKeyboard.keyboardLayout.uppercase.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 0),
            customKeyboard.keyboardLayout.uppercaseToggled.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 0),
            customKeyboard.keyboardLayout.lowercase.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 0),
            //c
            customKeyboard.keyboardLayout.uppercase.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 2),
            customKeyboard.keyboardLayout.uppercaseToggled.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 2),
            customKeyboard.keyboardLayout.lowercase.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 2),
            //n
            customKeyboard.keyboardLayout.uppercase.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 5),
            customKeyboard.keyboardLayout.uppercaseToggled.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 5),
            customKeyboard.keyboardLayout.lowercase.getSubKeyboardButton(atRowIndex: 2, subindex: 1, buttonIndex: 5),
            
        ]
        
        let specialItemStyle =  KeyMenuItemStyle(
            font: UIFont.systemFont(ofSize: 21),
            separatorColor: #colorLiteral(red: 0.9764705882, green: 0.9803921569, blue: 0.9803921569, alpha: 1),
            separatorWidth: 0.5)
        
        for specialButton in specialButtons {
            var items: [KeyMenuItem] = []
            let letter = (specialButton?.textLabel?.text!)!
            
            items.append(KeyMenuItem(title: (specialButton?.textLabel?.text!)!, style: specialItemStyle, action: { _ in self.sendInput(keyTitle: (specialButton?.textLabel?.text!)!) }))
            
            for code in letterModifiers[letter.lowercased()]!{

                //U+0300 ... U+036F are Combining Diacritical Marks
                if code.getUnicodeCodePoints() < "300" || code.getUnicodeCodePoints() > "36F"{
                    if letter == letter.uppercased(){
                        if code.getUnicodeCodePoints() != "DF"{
                            items.append(KeyMenuItem(title: code.uppercased(), style: specialItemStyle, action: { _ in self.sendInput(keyTitle: code.uppercased()) }))
                        }
                    }else{
                        items.append(KeyMenuItem(title: code.lowercased(), style: specialItemStyle, action: { _ in self.sendInput(keyTitle: code.lowercased()) }))
                    }
                }else{
                    items.append(KeyMenuItem(title: (specialButton?.textLabel?.text!)! + code, style: specialItemStyle, action: { _ in self.sendInput(keyTitle: (specialButton?.textLabel?.text!)! + code) }))
                }
                
            }
            
            let menu = KeyMenu(
                items: items,
                style: KeyMenuStyle(itemSize: CGSize(width: 29, height: 35)),
                type: .Special)
            menu.backgroundColor = KeyboardViewController.mainKeys
            
            specialButton?.keyMenu = menu
            menu.setCustomKeyboard(keyboard: customKeyboard)
        }
        
    }
    // é "\u{301}",è "\u{300}", ë "\u{308}", ê "\u{302}", ȩ"\u{327}", ė "\u{307}", ē "\u{304}"]
    let letterModifiers: [String:[String]] = ["e":["\u{300}","\u{301}","\u{302}","\u{308}","\u{304}","\u{307}","\u{327}"],
                                              "y":["\u{308}"],
                                              "u":["\u{302}","\u{308}","\u{300}","\u{301}","\u{304}"],
                                              "i":["\u{302}","\u{308}","\u{301}","\u{304}","\u{327}","\u{300}"],
                                              "o":["\u{302}","\u{308}","\u{300}","\u{301}","\u{152}","\u{0F8}","\u{304}","\u{303}"],
                                              "a":["\u{300}","\u{301}","\u{302}","\u{308}", "\u{0E6}", "\u{303}","\u{30A}","\u{304}"],
                                              "s":["\u{0DF}","\u{301}","\u{30C}"],
                                              "d":["\u{D0}"],
                                              "l":["\u{142}"],
                                              "z":["\u{30C}","\u{301}","\u{307}"],
                                              "c":["\u{327}","\u{301}","\u{30C}"],
                                              "n":["\u{303}","\u{301}"]
    ]
    
    // MARK: CustomKeyboardDelegate
    func customKeyboard(customKeyboard: CustomKeyboard, keyboardButtonPressed keyboardButton: KeyboardButton) {
        if customKeyboard == self.customKeyboard {
            if keyboardButton.identifier == "customButton" {
               //print("custom button pressed")
            }
        }
    }
    
    func customKeyboard(customKeyboard: CustomKeyboard, keyButtonPressed key: String) {
        if customKeyboard == self.customKeyboard {
            
            sendInput(keyTitle: key)
        }
    }
    
    func customKeyboardSpaceButtonPressed(customKeyboard: CustomKeyboard) {
        if customKeyboard == self.customKeyboard {
            correctInput()
            sendInputSpace(keyTitle: " ")
        }
    }
    
    func customKeyboardBackspaceButtonPressed(customKeyboard: CustomKeyboard) {
        if customKeyboard == self.customKeyboard {
            if CustomKeyboard.autoDeleteOngoing{
                textDocumentProxy.deleteBackward()
            }else{
                if CustomKeyboard.saveMassDelete{
                    saveMassDelete()
                    CustomKeyboard.saveMassDelete = false
                }else{
                    deleteInput()
                }
            }
            
        }
    }
    
    func customKeyboardReturnButtonPressed(customKeyboard: CustomKeyboard) {
        if customKeyboard == self.customKeyboard {
            textDocumentProxy.insertText("\n")
        }
    }
    
    func isOpenAccessGranted() -> Bool{
        let originalString = UIPasteboard.general.string
        UIPasteboard.general.string = "CHECK"
        if UIPasteboard.general.hasStrings {
            UIPasteboard.general.string = originalString ?? ""
            return true
        }else{
            return false
        }
    }
    
    func correctInput(){
        if stopSpellCheck == true || openAccessEnabled != true || autoCorrectEnabled != true{
            return
        }
        let before = textDocumentProxy.documentContextBeforeInput
        let token = before?.components(separatedBy: " ").last
        let textChecker = UITextChecker()
        if token == nil{
            return
        }
        let misspelledRange = textChecker.rangeOfMisspelledWord(in: token!, range: NSRange(0..<token!.utf16.count), startingAt: 0, wrap: false, language: preferredLanguage)
        
        if misspelledRange.location != NSNotFound,
            let guesses = textChecker.guesses(forWordRange: misspelledRange, in: token!, language: preferredLanguage) {
            if guesses.count == 0{
                return
            }
            let newWord = { () -> String in
                if (guesses.first!.contains("-")){
                    for each in guesses{
                        if each.contains(" "){
                            return each
                        }
                    }
                }
                return guesses.first!
            }
            for i in 1...token!.count{
                (textDocumentProxy as UIKeyInput).deleteBackward()
                if i == token!.count{
                    (textDocumentProxy as UIKeyInput).insertText(newWord())
                }
            }
            
        }
        
    }
    func spellCheck(word:String)->String{
        //var correctStr : String = String()
        let textChecker = UITextChecker()
        
        let misspelledRange = textChecker.rangeOfMisspelledWord(in: word, range: NSRange(0..<word.utf16.count), startingAt: 0, wrap: false, language: preferredLanguage)
        
        if misspelledRange.location != NSNotFound,
            let guesses = textChecker.guesses(forWordRange: misspelledRange, in: word, language: preferredLanguage) {
            return guesses.first!
            
        }
        return word
    }
    func notEndingPunctuation(index:Character)->Bool{
        let char = String(index)
        switch char{
        case " ",".","?",":",";",",","!","-":
            return false
        default:
            return true
        }
    }
    func notEndingPunctuationSpace(index:Character)->Bool{
        let char = String(index)
        switch char{
        case ".","?",":",";",",","!","-":
            return false
        default:
            return true
        }
    }
    
    func sendInputSpace(keyTitle: String){
        var before = textDocumentProxy.documentContextBeforeInput
        var after = textDocumentProxy.documentContextAfterInput
        
        (textDocumentProxy as UIKeyInput).insertText(keyTitle)
        
        if openAccessEnabled{
            stopSpellCheck = false
            if before != nil{
                
                if keyTitle == " " && before!.last == " " && before!.count > 1{
                    let index = before!.index((before?.endIndex)!, offsetBy: -2)
                    let subString = before![index]
                    
                    if notEndingPunctuation(index:subString){
                        (textDocumentProxy as UIKeyInput).deleteBackward()
                        (textDocumentProxy as UIKeyInput).deleteBackward()
                        (textDocumentProxy as UIKeyInput).insertText(". ")
                        //before = textDocumentProxy.documentContextBeforeInput
                        KeyboardViewController.caps = true
                        customKeyboard.capitalize()
                    }
                    
                }else{
                    if keyTitle == " " && String(before!.last!).rangeOfCharacter(from: characterset) != nil{
                        customKeyboard.backToLetters()
                        if !notEndingPunctuation(index: before!.last!){
                            customKeyboard.capitalize()
                        }
                    }
                }
                
                
            }
            before = textDocumentProxy.documentContextBeforeInput
            after = textDocumentProxy.documentContextAfterInput
            
            let documentContext = "\(before ?? "")\(after ?? "")"
            //NSLog("message: \(documentContext)")
            KeyboardViewController.keyInput!.recordAndWriteTextContext(AppString: hostBundleID, textField: documentContext)
            for each in suggestionList{
                each.setTitle("", for: .normal)
                each.isHidden = true
            }
            updateBorders()
        }
        
    }
    func saveMassDelete(){
        if openAccessEnabled{
            //NSLog("keyPressed: ⌫")
            let before = textDocumentProxy.documentContextBeforeInput
            let after = textDocumentProxy.documentContextAfterInput
            let documentContext = "\(before ?? "")\(after ?? "")"
           //print("\(documentContext)")
            KeyboardViewController.keyInput!.recordAndWriteTextContext(AppString: hostBundleID, textField: documentContext)
            
            if (before ?? "").count == 0{
                stopSpellCheck = false
                customKeyboard.capitalize()
                for each in suggestionList{
                    each.setTitle("", for: .normal)
                    each.isHidden = true
                }
                updateBorders()
            }else{
                if !notEndingPunctuationSpace(index:before!.last!){
                    customKeyboard.shiftLower()
                }
                stopSpellCheck = true
            }
            updateSuggestions()
        }
    }
    func deleteInput(){
        (textDocumentProxy as UIKeyInput).deleteBackward()
        
        if openAccessEnabled{
            //NSLog("keyPressed: ⌫")
            let before = textDocumentProxy.documentContextBeforeInput
            let after = textDocumentProxy.documentContextAfterInput
            let documentContext = "\(before ?? "")\(after ?? "")"
            //print("\(documentContext)")
            if (before ?? "").count != 0{
                
                if !notEndingPunctuationSpace(index:before!.last!){
                    customKeyboard.shiftLower()
                }
                //NSLog("message: \(documentContext)")
                KeyboardViewController.keyInput!.recordAndWriteTextContext(AppString: hostBundleID, textField: documentContext)
                stopSpellCheck = true
            }else{
                stopSpellCheck = false
                customKeyboard.capitalize()
                for each in suggestionList{
                    each.setTitle("", for: .normal)
                }
            }
            updateSuggestions()
        }
    }
    @objc func deleteWrap(){
        deleteInput()
    }
    @objc func sendInputWrap(button:UIButton){
        sendSuggestion(word: button.title(for: .normal)!)
        for each in suggestionList{
            each.setTitle("", for: .normal)
            each.isHidden = true
        }
        updateBorders()
    }
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
        
    }
    override func textDidChange(_ textInput: UITextInput?) {
        if openAccessEnabled{
            let before = textDocumentProxy.documentContextBeforeInput
            let after = textDocumentProxy.documentContextAfterInput
            if before != nil && after != nil{
                //print("\(before!)|\(after!)")
                updateSuggestions()
            }
        }
    }
    override func selectionDidChange(_ textInput: UITextInput?) {
        //print("selectionDidChange")
    }
    
    func sendInput(keyTitle: String){
        (textDocumentProxy as UIKeyInput).insertText(keyTitle)
        
        if openAccessEnabled{
            let before = textDocumentProxy.documentContextBeforeInput
            let after = textDocumentProxy.documentContextAfterInput
            let documentContext = "\(before ?? "")\(after ?? "")"
            KeyboardViewController.keyInput!.recordAndWriteTextContext(AppString: hostBundleID, textField: documentContext)
            updateSuggestions()
        }
        
    }
    
    let emojiGroups =   ["Frequently Used", "Smileys & People", "Animals & Nature", "Food & Drink", "Activities", "Travel & Places", "Objects", "Symbols", "Flags"]
    //let emojiCollectionGroups = ["😂","🐶","🍔","⚽️","🗺","💡","🔣","🏳️"]
    var customKeyboard: CustomKeyboard!
    var keyboardHeight: CGFloat = 0
    var rowSpaceing: CGFloat = 0
    static var layoutView: UIView?
    
    
    var emojiButton:UIButton = UIButton()
    var emojiDictionary: [String:[String]] = [:]
    
    var emojiCollectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    var middleView: UIView = UIView()
    let reuseIdentifier = "cell"
    var emojiControl = UISegmentedControl()
    var emojiStaticButtonView = UIView()
    var rowWidth: CGFloat = 0
    var rowHeight: CGFloat = 0
    
    var suggestionBarView = UIView()
    var suggestionOne = UIButton()
    var suggestionTwo = UIButton()
    var suggestionThree = UIButton()
    var suggestionList: [UIButton] = []
    var borderOne: CALayer = CALayer()
    var borderTwo: CALayer = CALayer()
    func updateBorders(){
        if allowSuggestions != true{
            return
        }
        for i in 1..<3{
            if suggestionList[i - 1].isHidden == true{
                switch i{
                case 1:
                    borderOne.isHidden = true
                default:
                    borderTwo.isHidden = true
                    
                }
            }else{
                switch i{
                case 1:
                    borderOne.isHidden = false
                default:
                    borderTwo.isHidden = false
                }
            }
        }
    }
    var stack: UIStackView = UIStackView()
    func setupSuggestionBar(){
        suggestionList.append(suggestionOne)
        suggestionOne.frame = CGRect(origin: CGPoint(x: 0,y : 0), size: CGSize(width: 0, height: 40))
        let color = KeyboardViewController.textColor
        borderOne.backgroundColor = color.cgColor
        borderOne.frame = CGRect(x: -1.5, y: 7, width: 1, height: 20)
        borderOne.isHidden = true
        suggestionTwo.layer.addSublayer(borderOne)
        
        suggestionList.append(suggestionTwo)
        suggestionTwo.frame = CGRect(origin: CGPoint(x: 0,y : 0), size: CGSize(width: 0, height: 40))
        borderTwo.backgroundColor = color.cgColor
        borderTwo.frame = CGRect(x: -1.5, y: 7, width: 1, height: 20)
        borderTwo.isHidden = true
        suggestionThree.layer.addSublayer(borderTwo)
        
        suggestionList.append(suggestionThree)
        suggestionThree.frame = CGRect(origin: CGPoint(x: 0,y : 0), size: CGSize(width: 0, height: 40))
        
        
        
        suggestionBarView = UIView(frame: CGRect(origin: CGPoint(x: 0,y : 5), size: CGSize(width: rowWidth, height: 40)))
        stack = createSubStack()
        stack.autoresizesSubviews = true
        stack.clipsToBounds = true
        
        suggestionBarView.backgroundColor = UIColor.clear
        for each in suggestionList{
            //each.textAlignment = .center
            each.setTitleColor(KeyboardViewController.textColor, for: .normal)
            each.titleLabel?.textAlignment = .center
            each.backgroundColor = UIColor.clear
            each.setTitle("", for: .normal)
            each.layer.cornerRadius = 20
            each.addTarget(self, action: #selector(sendInputWrap(button:)), for: .touchUpInside)
            each.autoresizingMask = .flexibleWidth
            each.titleLabel?.minimumScaleFactor = 0.1
            each.titleLabel?.adjustsFontSizeToFitWidth = true
            stack.addArrangedSubview(each)
        }
        suggestionBarView.addSubview(stack)
        stack.leftAnchor.constraint(equalTo: suggestionBarView.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: suggestionBarView.rightAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: suggestionBarView.bottomAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: suggestionBarView.topAnchor).isActive = true
        stack.distribution = .fillEqually
        
        
        KeyboardViewController.layoutView!.addSubview(suggestionBarView)
    }
    var allowSuggestions = false
    
    func toggleSuggestionBar(){
        allowSuggestions = true
        if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height{
            suggestionBarView.isHidden = false
            stack.isHidden = false

        }else{
            allowSuggestions = false
            suggestionBarView.isHidden = true
            stack.isHidden = true
            KeyboardViewController.layoutView!.sendSubviewToBack(suggestionBarView)
            for each in suggestionList{
                each.isHidden = true
            }
        }
    }
    func updateSuggestions(){
        if openAccessEnabled != true || allowSuggestions != true{
            return
        }
        let before = textDocumentProxy.documentContextBeforeInput
        let after = textDocumentProxy.documentContextAfterInput
        let beforeToken = before?.components(separatedBy: " ").last ?? ""
        let afterToken = after?.components(separatedBy: " ").first ?? ""
        if after != ""{
            customKeyboard.shiftLowerUnlessCapsLock()
        }
        let token = "\(beforeToken)\(afterToken)"
        let textChecker = UITextChecker()
        if token == ""{
            return
        }
        var guesses = textChecker.completions(forPartialWordRange: NSRange(0..<token.utf16.count), in: token, language: preferredLanguage)

        if guesses!.count != 0{
            //print("\(guesses!)")
            switch guesses!.count{
            case 1:
                suggestionOne.isHidden = false
                suggestionOne.setTitle(token, for: .normal)
                suggestionTwo.isHidden = false
                suggestionTwo.setTitle(guesses!.first!, for: .normal)
                suggestionThree.isHidden = true
                suggestionThree.setTitle("", for: .normal)
                updateBorders()
                return
            default:
                suggestionOne.setTitle(token, for: .normal)
                suggestionTwo.setTitle(guesses!.first!, for: .normal)
                suggestionThree.setTitle(guesses![1], for: .normal)
                UIView.animate(withDuration: 0, animations: {
                    for each in self.suggestionList{
                        each.isHidden = false
                    }
                })
                updateBorders()
                return
            }
        }else{
            let misspelledRange = textChecker.rangeOfMisspelledWord(in: token, range: NSRange(0..<token.utf16.count), startingAt: 0, wrap: true, language: preferredLanguage)
            
            if misspelledRange.location != NSNotFound,
                let guessAgain = textChecker.guesses(forWordRange: misspelledRange, in: token, language: preferredLanguage) {
                switch guessAgain.count{
                case 0:
                    suggestionOne.isHidden = true
                    suggestionOne.setTitle("", for: .normal)
                    suggestionTwo.isHidden = false
                    suggestionTwo.setTitle(token, for: .normal)
                    suggestionThree.isHidden = true
                    suggestionThree.setTitle("", for: .normal)
                    updateBorders()
                    return
                case 1:
                    suggestionOne.isHidden = false
                    suggestionOne.setTitle(token, for: .normal)
                    suggestionTwo.isHidden = false
                    suggestionTwo.setTitle(guessAgain.first!, for: .normal)
                    suggestionThree.isHidden = true
                    suggestionThree.setTitle("", for: .normal)
                    updateBorders()
                    return
                default:
                    suggestionOne.setTitle(token, for: .normal)
                    suggestionTwo.setTitle(guessAgain.first!, for: .normal)
                    suggestionThree.setTitle(guessAgain[1], for: .normal)
                    UIView.animate(withDuration: 0, animations: {
                        for each in self.suggestionList{
                            each.isHidden = false
                        }
                    })
                    updateBorders()
                    return
                }
            }else{
                suggestionOne.isHidden = true
                suggestionOne.setTitle("", for: .normal)
                suggestionTwo.isHidden = false
                suggestionTwo.setTitle(token, for: .normal)
                suggestionThree.isHidden = true
                suggestionThree.setTitle("", for: .normal)
                updateBorders()
            }

        }
    }
    
    func sendSuggestion(word:String){
        let before = textDocumentProxy.documentContextBeforeInput
        let after = textDocumentProxy.documentContextAfterInput
        let beforeToken = before?.components(separatedBy: " ").last ?? ""
        let afterToken = after?.components(separatedBy: " ").first ?? ""
        //print("\(beforeToken)|\(afterToken)")
        let token = "\(beforeToken)\(afterToken)"
        textDocumentProxy.adjustTextPosition(byCharacterOffset: afterToken.count)
        for i in 1...token.count{
            (textDocumentProxy as UIKeyInput).deleteBackward()
            if i == token.count{
                sendInput(keyTitle: word + " ")
            }
        }
    }

    /// Generates a single emoji UIButtons from a text String without adding target selector functions or animations.
    ///
    /// - Parameter title: A String emoji title
    /// - Returns: An emoji UIButton
    func setupEmojiScrollView(parentView: UIView){
        emoji_bar = UIView(frame: CGRect(origin: CGPoint(x: 0,y : 0), size: CGSize(width: rowWidth, height: 40)))
        emoji_bar.backgroundColor = KeyboardViewController.backgroundColor
        
        emojiBarLabel = UILabel(frame: CGRect(origin: CGPoint(x: 5,y : 0), size: CGSize(width: rowWidth - 5, height: 40)))
        emojiBarLabel.text = ""
        emojiBarLabel.textColor = KeyboardViewController.textColor
        emojiBarLabel.font = UIFont.boldSystemFont(ofSize: 16)
        emoji_bar.addSubview(emojiBarLabel)

        middleView = UIView(frame: CGRect(origin: CGPoint(x: 0,y : 0), size: CGSize(width: rowWidth, height: keyboardHeight - rowHeight)))
        emojiCollectionView = UICollectionView(frame: CGRect(origin: CGPoint(x: 0,y : 40), size: CGSize(width: rowWidth, height: keyboardHeight - (rowHeight + 40) )), collectionViewLayout: UICollectionViewFlowLayout.init())
        emojiCollectionView.showsHorizontalScrollIndicator = false
        popupFrame = UIView(frame: emojiCollectionView.frame)
        popupFrame.backgroundColor = UIColor.clear
        popupFrame.isHidden = true
        
        emojiStaticButtonView = UIView(frame: CGRect(origin: CGPoint(x: 0,y : middleView.frame.height), size: CGSize(width: rowWidth, height: rowHeight)))
        emojiStaticButtonView.backgroundColor = KeyboardViewController.backgroundColor
        
        middleView.addSubview(emoji_bar)
        middleView.addSubview(emojiCollectionView)
        middleView.addSubview(popupFrame)
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.emojiCollectionView.addGestureRecognizer(lpgr)
        
        let delButton = UIButton(frame: CGRect(x: rowWidth - (rowWidth/9), y: 0, width: rowWidth/9, height: rowHeight))
        
        delButton.setTitle("⌫", for: .normal)
        delButton.backgroundColor = KeyboardViewController.backgroundColor
        delButton.layer.cornerRadius = 5
        delButton.addTarget(self, action: #selector(deleteWrap), for: .touchUpInside)
        delButton.setTitleColor(KeyboardViewController.textColor, for: .normal)
        emojiStaticButtonView.addSubview(delButton)
        
        let abc = UIButton(frame: CGRect(x: 0, y: 0, width: rowWidth/9, height: rowHeight))
        
        abc.setTitle("abc", for: .normal)
        abc.backgroundColor = KeyboardViewController.backgroundColor
        abc.layer.cornerRadius = 5
        abc.addTarget(self, action: #selector(emojiKeyboard), for: .touchUpInside)
        abc.setTitleColor(KeyboardViewController.textColor, for: .normal)
        emojiStaticButtonView.addSubview(abc)
        
        // Setup Emoji UISegmentedControl
        
        if rowHeight <= 0{
            //apparently this value won't break the autoresizing constraints before rowHeight is set.
            KeyboardViewController.segmentHeight = 3
        }else{
            KeyboardViewController.segmentHeight = rowHeight - 3
        }
        
        let stackedViewsProvider = SegmentedControlStackedViewsProvider()
        
        emojiControl = stackedViewsProvider.views[0] as! UISegmentedControl
        
        emojiControl.addTarget(self, action: #selector(changeColor), for: .valueChanged)
        emojiControl.frame = CGRect(x: rowWidth/9 + 1, y: 0, width: (rowWidth - (2*(rowWidth/9))) - 1, height: rowHeight - 3)
        
        // Props to Trần Minh Quang's StackOverflow answer
        // for how to fix image scaling for borderless UISegementedControl
        // https://stackoverflow.com/a/50192205/7507949
        
        emojiControl.subviews.flatMap{$0.subviews}.forEach { subview in
            if let imageView = subview as? UIImageView, let image = imageView.image, image.size.width > 5 {
                // The imageView which isn't separator
                imageView.contentMode = .scaleAspectFill
            }
        }
        
        emojiStaticButtonView.addSubview(emojiControl)
        
        emojiCollectionView.register(MyCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)

        emojiCollectionView.setCollectionViewLayout(layout, animated: true)
        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        emojiCollectionView.backgroundColor = KeyboardViewController.backgroundColor
        
        var heightCellDivisor: CGFloat = 4
        var widthCellDivisor: CGFloat = 8
        if(UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height){
            heightCellDivisor = 4
            widthCellDivisor = 8
        }else{
            
            heightCellDivisor = 3
            widthCellDivisor = 13
        }
        
        layout.itemSize = CGSize(width: emojiCollectionView.frame.width / (widthCellDivisor), height: emojiCollectionView.frame.height / (heightCellDivisor))
        
        parentView.addSubview(middleView)
        //buttonView is not a subview of middleView so that middleView may be removed to increase performance
        self.view.addSubview(emojiStaticButtonView)
        emojiCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        emojiStaticButtonView.isHidden = true
        
        middleView.isHidden = true
        //parentView.addSubview(middleView)
        //middleView.removeFromSuperview()
    }
    
    @objc func emojiKeyboard(){
        if self.middleView.isHidden {
            middleView.isHidden = false
            emojiStaticButtonView.isHidden = false
            
            //Remove the emojiView when not being used to save memory
            if !self.middleView.isDescendant(of: self.view){
                self.view.addSubview(middleView)
            }
            
            self.view.bringSubviewToFront(emojiStaticButtonView)
            //emojiButton.removeFromSuperview()
        }else{
            middleView.isHidden = true
            emojiStaticButtonView.isHidden = true
            middleView.removeFromSuperview()
            //suggestionBar.addSubview(emojiButton)
        }
    }
    
    @objc func autoCorrectToggle(){
        if autoCorrectEnabled{
            EarsKeyboardService.shared.setAutoCorrectEnabled(newValue: false)
            autoCorrectEnabled = false
            for button in globeButtons!{
                button?.keyMenu?.items[2].titleLabel?.text = "Enable Autocorrect"
            }
            
        }else{
            EarsKeyboardService.shared.setAutoCorrectEnabled(newValue: true)
            autoCorrectEnabled = true
            for button in globeButtons!{
                button?.keyMenu?.items[2].titleLabel?.text = "Disable Autocorrect"
            }
        }
        
    }
    
    //var buttonBar:UIView = UIView()
    @objc func changeColor(sender: UISegmentedControl) {
        emojiCollectionView.scrollToItem(at: IndexPath(item: 0, section: sender.selectedSegmentIndex), at: .left, animated: false)
        emojiBarLabel.text = "\(emojiGroups[sender.selectedSegmentIndex])"
        //buttonBar.frame.origin.x = (sender.frame.width / CGFloat(sender.numberOfSegments)) * CGFloat(sender.selectedSegmentIndex) + emojiControl.frame.origin.x
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionCount =  emojiDictionary[emojiGroups[section]]!.count
        return sectionCount
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return emojiGroups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell =  emojiCollectionView.cellForItem(at: indexPath) as! MyCollectionViewCell
        let title = cell.emojiButton.text
        
        if !(emojiDictionary["Frequently Used"]?.contains(title!))!{
            if emojiDictionary["Frequently Used"]?.count == 32{
                emojiDictionary["Frequently Used"]?.remove(at: 31)
            }
            emojiDictionary["Frequently Used"]?.insert(title!, at: 0)
            EarsKeyboardService.shared.setFrequentlyUsed(newValue:  emojiDictionary["Frequently Used"]!)
        }else{
            let index = (emojiDictionary["Frequently Used"]?.firstIndex(of: title!))!
            emojiDictionary["Frequently Used"]?.remove(at: index)
            
            emojiDictionary["Frequently Used"]?.insert(title!, at: 0)
            EarsKeyboardService.shared.setFrequentlyUsed(newValue:  emojiDictionary["Frequently Used"]!)
        }
        
        collectionView.reloadSections(IndexSet(integer: 0))
        sendInput(keyTitle: title!)
        //(textDocumentProxy as UIKeyInput).insertText(title!)
        
        
    }
    
    var emojiControlCount = 0
    var prevControlSection = 0
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        let emo = emojiDictionary[emojiGroups[indexPath.section]]![indexPath.row]
        cell.emojiButton.translatesAutoresizingMaskIntoConstraints = false
        //let frame = cell.superview?.convert(cell.frame, to: nil)
        
        let map = collectionView.indexPathsForVisibleItems.map { $0[0] }
        let counts = map.reduce(into: [:]) { counts, section in counts[section, default: 0] += 1 }
        
        if counts.count == 2{
            var currentKeys: [IndexPath.Element] = []
            for each in counts.keys{
                currentKeys.append(each)
            }
            currentKeys = currentKeys.sorted(by: {$0 < $1})
            if currentKeys.contains(0){
                if (emojiDictionary["Frequently Used"]!.count < 16){
                    emojiControl.selectedSegmentIndex = currentKeys[0]
                    emojiBarLabel.text = "\(emojiGroups[currentKeys[0]])"
                }else{
                    if (counts[currentKeys[0]])! > (counts[currentKeys[1]])!{
                        emojiControl.selectedSegmentIndex = currentKeys[0]
                        emojiBarLabel.text = "\(emojiGroups[currentKeys[0]])"
                    }else{
                        emojiControl.selectedSegmentIndex = currentKeys[1]
                        emojiBarLabel.text = "\(emojiGroups[currentKeys[1]])"
                    }
                }
            }else{
                if (counts[currentKeys[0]])! > (counts[currentKeys[1]])!{
                    emojiControl.selectedSegmentIndex = currentKeys[0]
                    emojiBarLabel.text = "\(emojiGroups[currentKeys[0]])"
                }else{
                    emojiControl.selectedSegmentIndex = currentKeys[1]
                    emojiBarLabel.text = "\(emojiGroups[currentKeys[1]])"
                }
            }
            
        }else{
            
            if counts.count == 1{
                var currentKeys: [IndexPath.Element] = []
                for each in counts.keys{
                    currentKeys.append(each)
                }
                emojiControl.selectedSegmentIndex = currentKeys[0]
                emojiBarLabel.text = "\(emojiGroups[currentKeys[0]])"
            }
 
        }
        
        cell.addSubview(cell.emojiButton)
        let labelGuide = cell.layoutMarginsGuide
        
        cell.emojiButton.centerYAnchor.constraint(equalTo: labelGuide.centerYAnchor).isActive = true
        cell.emojiButton.centerXAnchor.constraint(equalTo: labelGuide.centerXAnchor).isActive = true
        cell.clipsToBounds = false
        cell.emojiString = emo

        if peopleModifierDict.keys.contains(cell.emojiString){
            if peopleModifierDict[cell.emojiString] != ""{
                cell.emojiButton.text = peopleModifierDict[cell.emojiString]
            }else{
                cell.emojiButton.text = emo
            }
        }else{
            cell.emojiButton.text = emo
        }
        cell.emojiButton.font = UIFont.boldSystemFont(ofSize: 32)
        
        return cell
    }
    var scrollEnabled = false
    var currentCell:MyCollectionViewCell?
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UILongPressGestureRecognizer){
            
            let p = gestureRecognizer.location(in: self.emojiCollectionView)
            let indexPath = self.emojiCollectionView.indexPathForItem(at: p)
            
            if let index = indexPath {
                //TODO put a guard statement here
                if let cell = self.emojiCollectionView.cellForItem(at: index) as? MyCollectionViewCell {
                    let title = cell.emojiString
                    if !canModify.contains(title){
                        return true
                    }else{
                        currentCell = cell
                    }
                }
            }
        }
        return false
    }
    var pop:UIView?
    var selectedLabel:UILabel?
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizer.State.ended {
            if selectedLabel != nil{
                emojiMenuObjectPressed(text: (selectedLabel?.text!)!)
                //sendInput(keyTitle: (selectedLabel?.text!)!)
                selectedLabel = nil
            }
            if pop != nil{
                pop!.removeFromSuperview()
            }
            pop = nil
            self.popupFrame.isHidden = true
            return
        }
        if gestureReconizer.state == UIGestureRecognizer.State.began {
            let p = gestureReconizer.location(in: self.emojiCollectionView)
            let indexPath = self.emojiCollectionView.indexPathForItem(at: p)
            if indexPath?.section == 0{
                return
            }
            if let index = indexPath {
                let cell = self.emojiCollectionView.cellForItem(at: index) as! MyCollectionViewCell
                let title = cell.emojiString
                
                if canModify.contains(title){
                    scrollEnabled = false
                    popupFrame.isHidden = false
                    let globalPoint = cell.superview?.convert(cell.frame.origin, to: nil)
                    pop = createEmojiMenu(emojiOrigin: globalPoint!,emojiWidth: cell.frame.width,emojiHeight: cell.frame.height, parentFrame: popupFrame.frame, emojiString: title)
                    popupFrame.addSubview(pop!)
                    
                }else{
                    scrollEnabled = true
                    return
                }
                
                //print(index.row)
            } else {
                //print("Could not find index path")
            }
        }
        if gestureReconizer.state == .began || gestureReconizer.state == .changed {
            
            let loc = gestureReconizer.location(in: self.view)
            //print("\(loc)")
            //(textDocumentProxy as UIKeyInput).insertText("loc:\(loc)\n")
            for subview in currentContent.subviews {
                for button in subview.subviews{
                    let buttonBounds = button.convert(button.bounds, to: self.view)
                    if buttonBounds.contains(loc){
                        let forcedButton = button as! UILabel
                        selectedLabel?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                        
                        selectedLabel = forcedButton
                        forcedButton.backgroundColor = #colorLiteral(red: 0.5375460386, green: 0.709213078, blue: 0.9995551705, alpha: 1)
                        
                    }
                    
                }
            }
            // note: 'view' is optional and need to be unwrapped
            //gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y + translation.y)
            //gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    var selectedButton:UIButton?
    @objc func handlePopupButtonSelect(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            let loc = gestureRecognizer.location(in: self.view)
            //print("\(loc)")
            //(textDocumentProxy as UIKeyInput).insertText("loc:\(loc)\n")
            for subview in currentContent.subviews {
                for button in subview.subviews{
                    let buttonBounds = button.convert(button.bounds, to: self.view)
                    if buttonBounds.contains(loc){
                        let forcedButton = button as! UIButton
                        
                        selectedButton = forcedButton
                        forcedButton.backgroundColor = UIColor.red
                        
                    }else{
                        let forcedButton = button as! UIButton
                        if forcedButton.currentTitle == selectedButton?.currentTitle{
                            selectedButton?.backgroundColor = UIColor.blue
                            selectedButton = nil
                        }
                        
                    }
                    
                }
            }
        }
        
    }
    func createSubStack() -> UIStackView{
        let verticalStack = UIStackView()
        verticalStack.axis = .horizontal
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        verticalStack.distribution = UIStackView.Distribution.equalSpacing
        verticalStack.alignment = UIStackView.Alignment.leading
        //verticalStack.spacing = 0.5
        
        return verticalStack
    }
    
    @objc func keyPressed(sender: AnyObject?) {
        let button = sender as! UIButton
        let title = button.title(for: .normal)
        sendInput(keyTitle: title!)
    }
    
    @objc func emojiMenuObjectPressed(text: String) {
        setNewEmojiDefault(text: text)
        if !(emojiDictionary["Frequently Used"]?.contains(text))!{
            if emojiDictionary["Frequently Used"]?.count == 32{
                emojiDictionary["Frequently Used"]?.remove(at: 31)
            }
            emojiDictionary["Frequently Used"]?.insert(text, at: 0)
            EarsKeyboardService.shared.setFrequentlyUsed(newValue: emojiDictionary["Frequently Used"]!)
        }else{
            let index = (emojiDictionary["Frequently Used"]?.firstIndex(of: text))!
            emojiDictionary["Frequently Used"]?.remove(at: index)
            
            emojiDictionary["Frequently Used"]?.insert(text, at: 0)
            EarsKeyboardService.shared.setFrequentlyUsed(newValue: emojiDictionary["Frequently Used"]!)
        }
        
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
        sendInput(keyTitle: text)
    }
    func setNewEmojiDefault(text: String){
        let title = text
        if peopleModifierDict.keys.contains(currentCell!.emojiString){
            currentCell?.emojiButton.text = title
            peopleModifierDict[currentCell!.emojiString] = title
            EarsKeyboardService.shared.setPeopleModifierDict(newValue: peopleModifierDict)
        }else{
            if canModify.contains(currentCell!.emojiString){
                currentCell?.emojiButton.text = title
                peopleModifierDict[currentCell!.emojiString] = title
                EarsKeyboardService.shared.setPeopleModifierDict(newValue: peopleModifierDict)
            }
        }
    }
    
    var currentContent = UIView()
    func createEmojiMenu(emojiOrigin: CGPoint, emojiWidth: CGFloat, emojiHeight: CGFloat, parentFrame: CGRect, emojiString: String) -> UIView {
        //print("\(emojiOrigin),\(emojiWidth),\(emojiHeight)")
        let content = UIView()
        let padding = CGFloat(5)
        let portraitShift: CGFloat = UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height ? 3 : -6
        let setWidth = ((emojiWidth + 2) * 6) + 8
        
        if emojiOrigin.x < emojiWidth{
            content.frame.origin.x = -1 * emojiOrigin.x
        }else{
            if emojiOrigin.x + setWidth > parentFrame.width{
                content.frame.origin.x = -((emojiOrigin.x + setWidth) - parentFrame.width)
            }else{
                content.frame.origin.x = -emojiWidth
            }
        }
        
        //content.frame.origin.x = -emojiWidth
        content.frame.origin.y = -(emojiHeight + 2)
        content.frame.size.width = setWidth
        content.frame.size.height = emojiHeight
        content.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        content.layer.cornerRadius = 5 * 1.5
        content.clipsToBounds = true
        
        var contentPos: CGFloat = 5

        for each in modifiers{
            let button = UIButton(frame: CGRect(x: contentPos, y: 0, width: emojiWidth, height: emojiHeight))
            //print("\(emojiString.decode(insert: each))")
            button.setTitle("\(emojiString.decode(insert: each))", for: .normal)
            button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            button.clipsToBounds = false
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.setTitleColor(KeyboardViewController.textColor, for: .normal)
            //sbutton.addTarget(self, action: #selector(emojiMenuObjectPressed(sender:)), for: .touchUpInside)
            button.layer.cornerRadius = 10
            button.titleLabel?.layer.cornerRadius = 10
            content.addSubview(button)
            contentPos += (emojiWidth + 2)
        }
        
        let bottomRect = CGRect(
            x: 0,
            y: -padding - 1, // a little hack for filling the gap
            width: emojiWidth,
            height: emojiHeight)
        var path = UIBezierPath()
        
        
        path = UIBezierPath(
            roundedRect: content.frame,
            byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(
                width: 5 * 1.5,
                height: 5 * 1.1))
        path.append(UIBezierPath(
            roundedRect: bottomRect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(
                width: 5,
                height: 5)))
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        let popup = UIView(
            frame: CGRect(
                x: emojiOrigin.x,
                y: (emojiOrigin.y + padding + portraitShift) - (emojiHeight),
                width: setWidth,
                height: emojiHeight + emojiHeight))
        popup.addSubview(content)
        currentContent = content
        popup.layer.insertSublayer(mask, at: 0)
        return popup
    }
    
}
// Credit for help with custom emoji segmented control goes to Ken Boreham's Guide @kenboreham￼
// https://kenb.us/how-to-customize-uisegmentedcontrol-without-losing-your-mind

//===========================================
// MARK: UIImage extension
//===========================================
extension UIImage {
    static func render(size: CGSize, _ draw: () -> Void) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        draw()
        
        return UIGraphicsGetImageFromCurrentImageContext()?
            .withRenderingMode(.alwaysTemplate)
    }
    
    static func make(size: CGSize, color: UIColor = #colorLiteral(red: 0.03529411765, green: 0.1568627451, blue: 0.3607843137, alpha: 1)) -> UIImage? {
        return render(size: size) {
            color.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
    }
}

//===========================================
// MARK: SegmentedControlFactory
//===========================================
protocol SegmentedControlImageFactory {
    var edgeOffset: CGFloat { get }
    func background(color: UIColor) -> UIImage?
    func divider(leftColor: UIColor, rightColor: UIColor) -> UIImage?
}

extension SegmentedControlImageFactory {
    var edgeOffset: CGFloat { return 0 }
    func background(color: UIColor) -> UIImage? { return nil }
    func divider(leftColor: UIColor, rightColor: UIColor) -> UIImage? { return nil }
}

struct DefaultSegmentedControlImageFactory: SegmentedControlImageFactory { }

//===========================================
// MARK: Underline
//===========================================
struct UnderlinedSegmentedControlImageFactory: SegmentedControlImageFactory {
    var size = CGSize(width: 2, height: 29)
    var lineWidth: CGFloat = 2
    
    func background(color: UIColor) -> UIImage? {
        return UIImage.render(size: size) {
            color.setFill()
            UIRectFill(CGRect(x: 0, y: size.height-lineWidth, width: size.width, height: lineWidth))
        }
    }
    
    func divider(leftColor: UIColor, rightColor: UIColor) -> UIImage? {
        return UIImage.render(size: size) {
            UIColor.clear.setFill()
        }
    }
}


//===========================================
// MARK: Segmented Control Builder
//===========================================
struct SegmentedControlBuilder {
    var boldStates: [UIControl.State] = [.selected, .highlighted]
    var boldFont = UIFont.boldSystemFont(ofSize: 14)
    var tintColor = #colorLiteral(red: 0.03529411765, green: 0.1568627451, blue: 0.3607843137, alpha: 1)
    var apportionsSegmentWidthsByContent = true
    
    private let imageFactory: SegmentedControlImageFactory
    
    init(imageFactory: SegmentedControlImageFactory = DefaultSegmentedControlImageFactory()) {
        self.imageFactory = imageFactory
    }
    
    func makeSegmentedControl(items: [UIImage]) -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: items)
        build(segmentedControl: segmentedControl)
        if KeyboardViewController.segmentHeight != nil {
            segmentedControl.heightAnchor.constraint(equalToConstant: KeyboardViewController.segmentHeight!).isActive = true
        }
        return segmentedControl
    }
    
    func makeSegmentedControl(items: [String]) -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: items)
        build(segmentedControl: segmentedControl)
        return segmentedControl
    }
    @available(iOS 13.0, *)
    var osTheme: UIUserInterfaceStyle {
        return UIScreen.main.traitCollection.userInterfaceStyle
    }
    
    func build(segmentedControl: UISegmentedControl) {
        segmentedControl.apportionsSegmentWidthsByContent = apportionsSegmentWidthsByContent
        segmentedControl.tintColor = tintColor
        if #available(iOSApplicationExtension 13.0, *) {
        if osTheme == .dark{
            segmentedControl.tintColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            }
        }
        
        segmentedControl.selectedSegmentIndex = 0
        
        boldStates
            .forEach { (state: UIControl.State) in
                let attributes = [NSAttributedString.Key.font: boldFont]
                segmentedControl.setTitleTextAttributes(attributes, for: state)
        }
        
        let controlStates: [UIControl.State] = [
            .normal,
            .selected,
            .highlighted,
            [.highlighted, .selected]
        ]
        
        controlStates.forEach { state in
            let image = background(for: state)
            segmentedControl.setBackgroundImage(image, for: state, barMetrics: .default)
            
            controlStates.forEach { state2 in
                let image = divider(leftState: state, rightState: state2)
                segmentedControl.setDividerImage(image, forLeftSegmentState: state, rightSegmentState: state2, barMetrics: .default)
            }
        }
        
        [.left, .right]
            .forEach { (type: UISegmentedControl.Segment) in
                let offset = positionAdjustment(forSegmentType: type)
                segmentedControl.setContentPositionAdjustment(offset, forSegmentType: type, barMetrics: .default)
        }
        
        segmentedControl.addTarget(SegmentedControlAnimationRemover.shared, action: #selector(SegmentedControlAnimationRemover.removeAnimation(_:)), for: .valueChanged)
    }
    
    private func color(for state: UIControl.State) -> UIColor {
        switch state {
        case .selected, [.selected, .highlighted]:
            return #colorLiteral(red: 0.03529411765, green: 0.1568627451, blue: 0.3607843137, alpha: 1)
        case .highlighted:
            return #colorLiteral(red: 0.03529411765, green: 0.1568627451, blue: 0.3607843137, alpha: 1).withAlphaComponent(0.5)
        default:
            return .clear
        }
    }
    
    private func background(for state: UIControl.State) -> UIImage? {
        return imageFactory.background(color: color(for: state))
    }
    
    private func divider(leftState: UIControl.State, rightState: UIControl.State) -> UIImage? {
        return imageFactory.divider(leftColor: color(for: leftState), rightColor: color(for: rightState))
    }
    
    private func positionAdjustment(forSegmentType type: UISegmentedControl.Segment) -> UIOffset {
        switch type {
        case .left:
            return UIOffset(horizontal: imageFactory.edgeOffset, vertical: 0)
        case .right:
            return UIOffset(horizontal: -imageFactory.edgeOffset, vertical: 0)
        default:
            return UIOffset(horizontal: 0, vertical: 0)
        }
    }
}

class SegmentedControlAnimationRemover {
    static var shared = SegmentedControlAnimationRemover()
    @objc func removeAnimation(_ control: UISegmentedControl) {
        control.layer.sublayers?.forEach { $0.removeAllAnimations() }
    }
}

//===========================================
// MARK: StackedViewsProvider
//===========================================
protocol StackedViewsProvider {
    var views: [UIView] { get }
}

class SegmentedControlStackedViewsProvider: StackedViewsProvider {
    let items = ["hourglass","key-emoji-group-emoji", "key-emoji-group-animals", "key-emoji-group-food", "key-emoji-group-activities","key-emoji-group-travel","key-emoji-group-objects","key-emoji-group-symbols", "key-emoji-group-flags"]
    

    lazy var views: [UIView] = {
        return [
            createView(imageFactory: UnderlinedSegmentedControlImageFactory(), items: items.map { UIImage(named: $0)!.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), resizingMode: .stretch) })
        ]
    }()
    
    private func createView(imageFactory: SegmentedControlImageFactory, items: [String]) -> UIView {
        let builder = SegmentedControlBuilder(imageFactory: imageFactory)
        return builder.makeSegmentedControl(items: items)
    }
    private func createView(imageFactory: SegmentedControlImageFactory, items: [UIImage]) -> UIView {
        let builder = SegmentedControlBuilder(imageFactory: imageFactory)
        return builder.makeSegmentedControl(items: items)
    }
}

//===========================================
// MARK: StackViewController
//===========================================
class StackViewController : UIViewController {
    let stackedViewsProvider: StackedViewsProvider
    
    init(stackedViewsProvider: StackedViewsProvider) {
        self.stackedViewsProvider = stackedViewsProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .darkGray
        self.view = view
        
        let stackView = UIStackView(arrangedSubviews: stackedViewsProvider.views)
        view.addSubview(stackView)
        
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 32
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
    }
}

extension UIButton {
    func setTitleWithoutAnimation(title: String?) {
        UIView.setAnimationsEnabled(false)
        
        setTitle(title, for: .normal)
        
        layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
    }
}

class MyCollectionViewCell: UICollectionViewCell {
    
    var emojiButton: UILabel = UILabel()
    var emojiString: String = ""
    
}
extension String {
    func getUnicodeCodePoints() -> String {
        let map = unicodeScalars.map { String($0.value, radix: 16, uppercase: true) }
        return map[0]
    }
    func encode() -> String {
        let data = self.data(using: .nonLossyASCII, allowLossyConversion: true)!
        return String(data: data, encoding: .utf8)!
    }
    func decode(insert: String) -> String{
        if insert == ""{
            return self
        }
        let uni = self.unicodeScalars // Unicode scalar values of the string
        var buildString = ""
        if uni.count == 1{
            return "\(self + insert)"
        }
        for i in 0...(uni.count - 1){
            let each = uni[uni.index(uni.startIndex, offsetBy: i)].value
            let code = String(each, radix: 16, uppercase: true)
            if i != (uni.count - 1){
                //print("\(i): \(code)")
                if code == "FE0F"{
                    continue
                }
                if i == 1{
                    let uniInsert = insert.unicodeScalars
                    let insert = uniInsert[uniInsert.startIndex].value
                    let insertCode = String(insert, radix: 16, uppercase: true)
                    buildString += "\(insertCode) \(code) "
                }else{
                    buildString += "\(code) "
                }
            }else{
                if i == 1{
                    let uniInsert = insert.unicodeScalars
                    let insert = uniInsert[uniInsert.startIndex].value
                    let insertCode = String(insert, radix: 16, uppercase: true)
                    buildString += "\(insertCode) \(code)"
                }else{
                    buildString += "\(code)"
                }
            }
        }
        //print("\(buildString)")
        return convertUnicode(input: buildString)
    }
}
