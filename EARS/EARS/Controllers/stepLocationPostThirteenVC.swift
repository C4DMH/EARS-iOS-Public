//
//  stepILocationPostThirteenVC.swift
//  EARS
//
//  Created by Wyatt Reed on 10/3/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import AMXFontAutoScale
import UIKit

class stepLocationPostThirteenVC: UIViewController {
    
    
    @IBOutlet weak var settingsButton: roundedButton!
    @IBOutlet weak var textView: UILocalizedTextView!
    @IBOutlet weak var titleLabel: UILocalizedLabel!
    
    @IBOutlet weak var continueButton: roundedButton!
    override func viewDidLoad() {
        super.viewDidLoad()
            
        
        textView.amx_fontSizeUpdateHandler = { originalSize, preferredSize, multiplier in

            let formattedString = NSMutableAttributedString()

            formattedString
                .normal("installTextPart1Alternate".localized(), fontSize: preferredSize)
                .bold("installTextPart2Alternate".localized(), fontSize: preferredSize)
                .normal("installTextPart3Alternate".localized(), fontSize: preferredSize)
                .bold("installTextPart4".localized(), fontSize: preferredSize)
                .normal("installTextPart5".localized(), fontSize: preferredSize)
                .bold("installTextPart6".localized(), fontSize: preferredSize)
                .normal("installTextPart7".localized(), fontSize: preferredSize)
                .bold("installTextPart8Alternate".localized(), fontSize: preferredSize)
                .normal("installTextPart9".localized(), fontSize: preferredSize)
                .bold("installTextPart10Alternate".localized(), fontSize: preferredSize)
                .normal("installTextPart13".localized(), fontSize: preferredSize)
                .italic("installTextPart14".localized(), fontSize: preferredSize)
                .normal("installTextPart15".localized(), fontSize: preferredSize)
            
            self.textView.attributedText = formattedString
        }
        textView.amx_autoScaleFont(forReferenceScreenSize: .size4p7Inch)

        if settingsButton != nil {
            settingsButton.addTarget(self, action: #selector(requestKeyboardUsage), for: .touchUpInside)
        }
        if continueButton != nil {
            continueButton.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)
        }
        if allowLocationStatus{
            continueButton.isEnabled = true
            continueButton.backgroundColor = #colorLiteral(red: 0.007843137255, green: 0.431372549, blue: 0.768627451, alpha: 1)
        }else{
            allowLocationStatus = true
        }
    }
    var allowLocationStatus = false
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
        appDelegate.changeRootViewController(with: "stepKeyboard")
    }
    deinit{
        //print("stepInstallKeyboard deinit invoked.")
    }
    
}
