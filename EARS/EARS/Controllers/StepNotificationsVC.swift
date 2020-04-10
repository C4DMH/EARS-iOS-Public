//
//  StepNotificationsVC.swift
//  EARS
//
//  Created by Wyatt Reed on 1/30/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale
import CoreMotion


class StepNotificationsVC: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyText: UITextView!
    
    @IBOutlet weak var stepNotificationButton: roundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4p7Inch)
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        stepNotificationButton.addTarget(self, action: #selector(requestPushNotifications), for: .touchUpInside)
    }
    
    @objc func requestPushNotifications(){
        
        if (AppDelegate.study?.includedSensors["accel"])! {
            //print("accel enabled for study")
            //Permission request will be presented here
            if CMMotionActivityManager.authorizationStatus() == .notDetermined {
                //Some devices might not have the proper hardware
                if CMMotionActivityManager.isActivityAvailable(){
                    let recorder = CMMotionActivityManager()
                    recorder.queryActivityStarting(from: Date(), to: Date(), to: .main) {  motionActivities, error in
                        if AppDelegate.lastMotionActivityCollection == 0{
                            let currentDateTime = Date()
                            AppDelegate.lastMotionActivityCollection = Int64(currentDateTime.timeIntervalSince1970 * 1000)
                            EarsService.shared.setLastMotionActivityCollection(newValue: Int64(currentDateTime.timeIntervalSince1970 * 1000))
                        }
                        AppDelegate.registerForPushNotifications()
                    }
                }else{
                    AppDelegate.registerForPushNotifications()
                }
                //Some devices might not have the proper hardware
                if CMSensorRecorder.isAccelerometerRecordingAvailable() {
                    if AppDelegate.lastMotionCollection == 0{
                        let currentDateTime = Date()
                        AppDelegate.lastMotionCollection = Int64(currentDateTime.timeIntervalSince1970 * 1000)
                        EarsService.shared.setLastMotionCollection(newValue: Int64(currentDateTime.timeIntervalSince1970 * 1000))
                    }
                }
            }else{
                AppDelegate.registerForPushNotifications()
            }
        }else{
            AppDelegate.registerForPushNotifications()
        }
        
        
        stepNotificationButton.setTitle("Continue".localized(), for: .normal)
        stepNotificationButton.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)
        
    }
    
    @objc func changeDefault() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if AppDelegate.study!.includedSensors["gps"]!{
            appDelegate.changeRootViewController(with: "stepLocation")
        }else{
            //Keyboard setup occurs even if we aren't collecting keyboard input
            appDelegate.changeRootViewController(with: "stepKeyboard")
        }
    }
}
