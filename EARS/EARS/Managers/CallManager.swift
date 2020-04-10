//
//  CallManager.swift
//  EARS
//
//  Created by Wyatt Reed on 8/14/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import CallKit


class CallManager{
    
    lazy var callDataString = "CALLSTATUS"
    
    func recordCallState(state: Research_CallEvent.State){
        let callProtoBuf = Research_CallEvent.with {
            $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            $0.state = state
        }
        
        let dataStorage = DataStorage()
        dataStorage.writeFileProto(dataType: callDataString, messageArray: [callProtoBuf])
    }
    
    deinit {
        //NSLog("CallManager Deinit invoked.")
    }
}

extension AppDelegate: CXCallObserverDelegate {
    
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded == true {
            //print("Disconnected")
            AppDelegate.call!.recordCallState(state: Research_CallEvent.State.disconnected) //"disconnected"
        }
        if call.isOutgoing == true && call.hasConnected == false {
            //print("Dialing")
            AppDelegate.call!.recordCallState(state: Research_CallEvent.State.dialing) //"dialing"

        }
        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            //print("Incoming")
            AppDelegate.call!.recordCallState(state: Research_CallEvent.State.incoming) //"incoming"

        }
        
        if call.hasConnected == true && call.hasEnded == false {
            //print("Connected")
            AppDelegate.call!.recordCallState(state: Research_CallEvent.State.connected) //"connected"

        }
    }
    
}
