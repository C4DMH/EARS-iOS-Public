//
//  StepZeroVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/9/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale


class StepZeroVC: UIViewController {

    @IBOutlet weak var button: roundedButton!
    
    @IBOutlet weak var bodyText: UITextView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)

        // Do any additional setup after loading the view.
        button.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)

    }
    
    @objc func changeDefault() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.changeRootViewController(with: "stepNotifications")
        
    }
    
    deinit{
        //NSLog("stepZero deinit invoked")
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
