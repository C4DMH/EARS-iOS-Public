//
//  stepMusicVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/31/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import MediaPlayer
import AMXFontAutoScale


class StepMusicVC: UIViewController {

    @IBOutlet weak var stepMusicButton: roundedButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyText: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        stepMusicButton.addTarget(self, action: #selector(requestMusicUsage), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func requestMusicUsage(){
        //let queue = DispatchQueue(label: "musicUsage")
        AppDelegate.requestMusicAccess()
        stepMusicButton.setTitle("Continue", for: .normal)
        stepMusicButton.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)
    }

    
    @objc func changeDefault() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if AppDelegate.study!.includedSensors["selfie"]!{
            appDelegate.changeRootViewController(with: "stepPhotoCapture")
        }else{
            appDelegate.changeRootViewController(with: "acknowledgement")
        }
 
    }
    
    deinit{
        //print("stepMusic deinit invoked.")
    }

}
