//
//  RiskAlertVC.swift
//  EARS
//
//  Created by Wyatt Reed on 3/7/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale


class RiskAlertVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var okayButton: roundedButton!
    @IBOutlet weak var bodyText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        bodyText.text = "riskBodyTextFull".localized()
        bodyText.amx_fontSizeUpdateHandler = { originalSize, preferredSize, multiplier in
            let formattedString = NSMutableAttributedString()
            formattedString
                .normal("riskBodyTextPart1".localized(), fontSize: preferredSize)
                .normal("riskBodyTextPart2".localized(), fontSize: 10)
                .normal("riskBodyTextPart3".localized(), fontSize: preferredSize)
                .normal("riskBodyTextPart4".localized(), fontSize: 10)
            self.bodyText.attributedText = formattedString
        }
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        okayButton.addTarget(self, action: #selector(backBarButtonTapped), for: .touchUpInside)

        // Do any additional setup after loading the view.
    }
    
    @IBAction func backBarButtonTapped(_ sender: AnyObject) {
        //delegate?.handShake(controller: self, text: "back")
        self.dismiss(animated: true, completion: nil)
        AppDelegate.homeInstance.chainEMAs()
    }

}


