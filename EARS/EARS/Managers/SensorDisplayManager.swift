//
//  SensorDisplayManager.swift
//  EARS
//
//  Created by Wyatt Reed on 2/11/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import Photos
import CoreMotion
import MediaPlayer
import UserNotifications


class SensorDisplayManager {
    let sensorNameDict:[String:String] = ["accel"   :"Accelerometer".localized(),
                                          "battery" :"Battery State".localized(),
                                          "gps"     :"GPS Location".localized(),
                                          "keyboard":"Keyboard Input".localized(),
                                          "ema"     :"EMA Surveys".localized(),
                                          "risk_ema": "Routine EMA Surveys".localized(),
                                          "music"   :"Music Choice".localized(),
                                          "motion_activity": "Motion & Fitness".localized(),
                                          "selfie"  :"Selfie Collection".localized(),
                                          "call"    :"Call Frequency".localized()
                                         ]
    
    func getPermissionStateForSensor(sensorName: String) -> Bool {
        switch sensorName {
        case "battery", "call":
            return true
        case "accel":
            if ( CMMotionActivityManager.authorizationStatus() == .authorized || !CMSensorRecorder.isAccelerometerRecordingAvailable()) {
                return true
            }
        case "keyboard":
            if isKeyboardExtensionEnabled() {
                return true
            }
        case "gps":
            if AppDelegate.gps.locationEnabled(){
                return true
            }
        case "music":
            if MPMediaLibrary.authorizationStatus() == MPMediaLibraryAuthorizationStatus.authorized{
                return true
            }
        case "motion_activity":
            if (CMMotionActivityManager.authorizationStatus() == .authorized || !CMMotionActivityManager.isActivityAvailable()){
                return true
            }
        case "ema", "risk_ema":
            return AppDelegate.pushCheckEnabled
        case "selfie":
            if PHPhotoLibrary.authorizationStatus() == .authorized{
                return true
            }
        default:
            return false
        }
        return false
    }
    
    func getDisplayName(name: String) -> String{
        if sensorNameDict.keys.contains(name){
            return sensorNameDict[name]!
        }else{
            return ""
        }
    }
    
    // How to detect whether custom keyboard is activated from the keyboard's container app?
    // https://stackoverflow.com/a/37263645/7507949
    // This does not check if Allow Full Access is enabled, only if the keyboard is enabled.
    func isKeyboardExtensionEnabled() -> Bool {
        guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
            NSLog("isKeyboardExtensionEnabled(): Cannot retrieve bundle identifier.")
            // Return true to be safe..
            return true
        }
        
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            // There is no key `AppleKeyboards` in NSUserDefaults. That happens sometimes.
            NSLog("isKeyboardExtensionEnabled(): here is no key `AppleKeyboards` in UserDefaults.")
            // Return true to be safe..
            return true
        }
        
        let keyboardExtensionBundleIdentifierPrefix = appBundleIdentifier + "."
        for keyboard in keyboards {
            //print("\(keyboard)")
            if keyboard.hasPrefix(keyboardExtensionBundleIdentifierPrefix) {
                return true
            }
        }
        
        return false
    }
    
}
