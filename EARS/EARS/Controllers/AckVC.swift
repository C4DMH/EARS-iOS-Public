//
//  AckVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/9/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale
import Firebase


class AckVC: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyText: UITextView!
    @IBOutlet weak var phoneBun: UIImageView?
    @IBOutlet weak var ackBackground: UIImageView?
    
    
    override func viewDidLoad() {
        setContext()
        super.viewDidLoad()
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        
        if !UIAccessibility.isReduceMotionEnabled {

            let min = CGFloat(-30)
            let max = CGFloat(30)
            
            let xMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x", type: .tiltAlongHorizontalAxis)
            xMotion.minimumRelativeValue = min
            xMotion.maximumRelativeValue = max
            
            let yMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y", type: .tiltAlongVerticalAxis)
            yMotion.minimumRelativeValue = min
            yMotion.maximumRelativeValue = max
            
            let motionEffectGroup = UIMotionEffectGroup()
            motionEffectGroup.motionEffects = [xMotion,yMotion]
            
            ackBackground!.addMotionEffect(motionEffectGroup)
        }
        let defaults = UserDefaults(suiteName: GROUP_IDENTIFIER)
        defaults?.set(AppDelegate.study?.study.uppercased(), forKey: "study_name")
        if !nonGameStudies.contains(AppDelegate.studyName.uppercased()){
            AppDelegate.gameEnabled = true
        }
        //Assuming we start the EMA phase immediately
        let phaseTuple = AppDelegate.study!.getEMAPhaseStartTuple()
        let phaseStart = phaseTuple[0]
        let phaseEnd = phaseTuple[1]
        
        AppDelegate.phaseStart = phaseStart
        AppDelegate.phaseEnd = phaseEnd

        EarsService.shared.setCurrentEMAPhaseStart(newValue: phaseStart)
        EarsService.shared.setCurrentEMAPhaseEnd(newValue: phaseEnd)
        
        
        AppDelegate.assignTimezoneTopic()
        /*
        Messaging.messaging().subscribe(toTopic: "ears-topic") { error in
            //NSLog("Subscribed to ears-topic")
        }
        */
        Messaging.messaging().subscribe(toTopic: (AppDelegate.study?.study)!) { error in
            //NSLog("Subscribed to \(AppDelegate.study?.study ?? "study")")
        }
        Messaging.messaging().subscribe(toTopic: AppDelegate.device_id) { error in
            //NSLog("Subscribed to \(UIDevice.current.identifierForVendor!.uuidString)")
        }
        
        
        AppDelegate.gps.locationManager.allowsBackgroundLocationUpdates = true
        AppDelegate.gps.locationManager.pausesLocationUpdatesAutomatically = false
        AppDelegate.gps.startLocationUpdates()
        AppDelegate.registerSensors()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.startCallObserver()
        //let them read the page before automatically switching to the homescreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: {
            appDelegate.changeRootViewController(with: "home")
        })
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ackBackground?.image = nil
        phoneBun?.image = nil

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit{
        //NSLog("ack deinit invoked.")
    }

    private func setContext(){
        EarsService.shared.setSetupComplete(newValue: true)
        AppDelegate.setupStatus = true
    }

}
