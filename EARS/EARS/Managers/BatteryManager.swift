//
//  BatteryManager.swift
//  EARS
//
//  Created by Wyatt Reed on 8/2/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import UIKit

class BatteryManager {

    lazy var batteryDataString = "BATTERY"

    static var batteryLevel: Float? = nil
    var charge_state: Research_BatteryEvent.State = Research_BatteryEvent.State.unknown

    
    init(){
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        var batteryLevel: Float {
            return UIDevice.current.batteryLevel
        }
        BatteryManager.batteryLevel = batteryLevel
        
        var currentChargeState: Research_BatteryEvent.State {
            switch(UIDevice.current.batteryState) {
                case .charging:
                    return Research_BatteryEvent.State.charging
                case .full:
                    return Research_BatteryEvent.State.full
                case .unplugged:
                    return Research_BatteryEvent.State.unplugged
                case .unknown:
                    return Research_BatteryEvent.State.unknown
                @unknown default:
                    NSLog("ERROR: Unknown battery state recorded.")
                    return Research_BatteryEvent.State.unknown
            }
        }
        self.charge_state = currentChargeState
        
        //NSLog("batteryLevel: \(BatteryManager.batteryLevel ?? 0), chargeState: \(BatteryManager.chargeState)")

    }
    
    
    /// Will set the chargeState and batteryLevel when called. This function is intended to be used with a notification to determine when the phone is actively charging as an upload condition
    func batteryStateDidChange() {
        var batteryLevel: Float {
            return UIDevice.current.batteryLevel
        }
        BatteryManager.batteryLevel = batteryLevel
        var currentChargeState: Research_BatteryEvent.State {
        switch(UIDevice.current.batteryState) {
            case .charging:
                return Research_BatteryEvent.State.charging
            case .full:
                return Research_BatteryEvent.State.full
            case .unplugged:
                return Research_BatteryEvent.State.unplugged
            case .unknown:
                return Research_BatteryEvent.State.unknown
            @unknown default:
                NSLog("ERROR: Unknown battery state recorded.")
                return Research_BatteryEvent.State.unknown
            }
        }
        self.charge_state = currentChargeState
        recordBatteryState(chargeState: currentChargeState, batteryLevel: batteryLevel)
        //NSLog("batteryLevel: \(BatteryManager.batteryLevel ?? 0), chargeState: \(BatteryManager.chargeState)")

    }
    
    func recordBatteryState(chargeState: Research_BatteryEvent.State, batteryLevel: Float){
        let batteryProtoBuf = Research_BatteryEvent.with {
            $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            $0.state = chargeState
            $0.level = batteryLevel
        }
        
        let dataStorage = DataStorage()
        dataStorage.writeFileProto(dataType: self.batteryDataString, messageArray: [batteryProtoBuf])
    }

}
