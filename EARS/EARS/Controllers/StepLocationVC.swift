//
//  StepLocationVC.swift
//  EARS
//
//  Created by Wyatt Reed on 1/30/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale


class StepLocationVC: UIViewController {

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyText: UITextView!
    
    
    @IBOutlet weak var stepLocationButton: roundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            bodyText.text = "stepLocationAlternateBodyText".localized()
            stepLocationButton.setTitle("stepLocationAlternateButtonText".localized(), for: .normal)
        }
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4p7Inch)
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)

        stepLocationButton.addTarget(self, action: #selector(requestLocationUsage), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    @objc func requestLocationUsage(){
        if AppDelegate.study!.includedSensors["gps"]!{
            AppDelegate.gps.locationManager.requestAlwaysAuthorization()
        }
        stepLocationButton.setTitle("Continue".localized(), for: .normal)
        stepLocationButton.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)
    }
    
    @objc func changeDefault() {
        if #available(iOS 13.0, *) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.changeRootViewController(with: "stepLocationPostThirteen")
        }else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.changeRootViewController(with: "stepKeyboard")
        }
    }

}
