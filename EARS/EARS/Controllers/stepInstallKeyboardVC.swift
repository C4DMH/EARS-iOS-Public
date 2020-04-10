//
//  stepInstallKeyboardVC.swift
//  EARS
//
//  Created by Wyatt Reed on 11/5/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import AMXFontAutoScale
import UIKit

class stepInstallKeyboardVC: UIViewController {
    
    @IBOutlet weak var stepKeyboardInstallButton: roundedButton!
    @IBOutlet weak var continueButton: roundedButton!
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Even if a study doesn't collect keyboard, it still has to be included in the install
        if !(AppDelegate.study?.includedSensors["keyboard"])! {
            if !AppDelegate.keyboardSetupStatus{
                continueButton.setTitle("continueButtonTextSkip".localized(), for: .normal)
            }
            //Text scaling library, rather tedious
            textView.amx_fontSizeUpdateHandler = { originalSize, preferredSize, multiplier in
                //print("For original size: \(originalSize) set preferred size: \(preferredSize), multiplier: \(multiplier)")
                //do text attribution
                let formattedString = NSMutableAttributedString()
                formattedString
                    .normal("installTextSkip1".localized(), fontSize: preferredSize)
                    .italic("\(self.continueButton.titleLabel!.text!)", fontSize: preferredSize)
                    .normal("installTextSkip2".localized(), fontSize: preferredSize)
                    .bold("installTextSkip3".localized(), fontSize: preferredSize)
                    .normal("installTextSkip4".localized(), fontSize: preferredSize)
                    .bold("installTextSkip5".localized(), fontSize: preferredSize)
                    .normal("installTextSkip6".localized(), fontSize: preferredSize)
                    .bold("installTextSkip7".localized(), fontSize: preferredSize)
                    .normal("installTextSkip8".localized(), fontSize: preferredSize)
                    .bold("installTextSkip9".localized(), fontSize: preferredSize)
                    .normal("installTextSkip10".localized(), fontSize: preferredSize)
                    .italic("installTextSkip11".localized(), fontSize: preferredSize)
                    .normal("installTextSkip12".localized(), fontSize: preferredSize)
                
                self.textView.attributedText = formattedString
            }
            continueButton.isEnabled = true
            continueButton.backgroundColor = #colorLiteral(red: 0.007843137255, green: 0.431372549, blue: 0.768627451, alpha: 1)
            textView.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        }else{
            //if the keyboard is not included, no keyboard data will be collected and a lax setup in presented.
            textView.amx_fontSizeUpdateHandler = { originalSize, preferredSize, multiplier in

                let formattedString = NSMutableAttributedString()

                formattedString
                    .normal("installTextPart1".localized(), fontSize: preferredSize)
                    .bold("installTextPart2".localized(), fontSize: preferredSize)
                    .normal("installTextPart3".localized(), fontSize: preferredSize)
                    .bold("installTextPart4".localized(), fontSize: preferredSize)
                    .normal("installTextPart5".localized(), fontSize: preferredSize)
                    .bold("installTextPart6".localized(), fontSize: preferredSize)
                    .normal("installTextPart7".localized(), fontSize: preferredSize)
                    .bold("installTextPart8".localized(), fontSize: preferredSize)
                    .normal("installTextPart9".localized(), fontSize: preferredSize)
                    .bold("installTextPart10".localized(), fontSize: preferredSize)
                    .normal("installTextPart11".localized(), fontSize: preferredSize)
                    .bold("installTextPart12".localized(), fontSize: preferredSize)
                    .normal("installTextPart13".localized(), fontSize: preferredSize)
                    .italic("installTextPart14".localized(), fontSize: preferredSize)
                    .normal("installTextPart15".localized(), fontSize: preferredSize)
                
                self.textView.attributedText = formattedString
            }
            textView.amx_autoScaleFont(forReferenceScreenSize: .size4p7Inch)
        }
        

        if stepKeyboardInstallButton != nil {
            stepKeyboardInstallButton.addTarget(self, action: #selector(requestKeyboardUsage), for: .touchUpInside)
        }
        if continueButton != nil {
            continueButton.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)
        }
        //print("\(AppDelegate.keyboardSetupStatus)")
        if AppDelegate.keyboardSetupStatus{
            continueButton.isEnabled = true
            continueButton.backgroundColor = #colorLiteral(red: 0.007843137255, green: 0.431372549, blue: 0.768627451, alpha: 1)
        }else{
            EarsService.shared.setKeyboardSetupStatus(newValue: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func requestKeyboardUsage(){
        
        if let settingUrl = URL(string:UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingUrl)
        }
        continueButton.isEnabled = true
        continueButton.backgroundColor = #colorLiteral(red: 0.007843137255, green: 0.431372549, blue: 0.768627451, alpha: 1)
    }
    
    @objc func changeDefault() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (AppDelegate.study?.includedSensors["keyboard"])! {
            appDelegate.changeRootViewController(with: "changeKeyboard")
        }else{
            if AppDelegate.study!.includedSensors["music"]!{
                appDelegate.changeRootViewController(with: "stepMusic")
            }else{
                if AppDelegate.study!.includedSensors["selfie"]!{
                    appDelegate.changeRootViewController(with: "stepPhotoCapture")
                }else{
                    appDelegate.changeRootViewController(with: "acknowledgement")
                }
            }
        }
    }
    
    deinit{
        //print("stepInstallKeyboard deinit invoked.")
    }
    
}
extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String, fontSize: CGFloat) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "HelveticaNeue-Medium", size: fontSize)!]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        
        return self
    }
    @discardableResult func italic(_ text: String, fontSize: CGFloat) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "HelveticaNeue-LightItalic", size: fontSize)!]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        
        return self
    }
    
    @discardableResult func normal(_ text: String, fontSize: CGFloat) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "HelveticaNeue-Light", size: fontSize)!]
        let normal = NSMutableAttributedString(string:text, attributes: attrs)
        append(normal)
        
        return self
    }
}
