//
//  EMAManager.swift
//  EARS
//
//  Created by Wyatt Reed on 10/10/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//
//  This class is used to keep a record of sent notifications resulting in an EMA Survey

import Foundation

class EMAManager {
    
    //var dataStorage: DataStorage = DataStorage(dataType: "EMA")
    //static var buffer = Array<UInt8>(repeating: 0, count: 0)
    lazy var emaDataString = "EMA"
    lazy var emaDailyDataString = "DAILY"
    lazy var emaRiskDataString = "RISK"
    
    lazy var emaLogDataString = "SurveyLog"
    
    func recordEMA(message: Research_EMAEvent){
        let dataStorage = DataStorage()
        dataStorage.writeFileProto(dataType: self.emaDataString, messageArray: [message])
    }
    
    func recordDailyEMA(message: Research_EMAEvent){
        let dataStorage = DataStorage()
        dataStorage.writeFileProto(dataType: self.emaDailyDataString, messageArray: [message])
    }
    
    func recordRiskEMA(message: Research_EMAEvent){
        let dataStorage = DataStorage()
        dataStorage.writeFileProto(dataType: self.emaRiskDataString, messageArray: [message])
    }
    
    func recordEMALog(){
        if AppDelegate.emaLog == nil{
            return
        }
        if AppDelegate.homeInstance == nil{
            return
        }
        
        if AppDelegate.emaLog?.keys.count == 0{
            return
        }
        
        //var buildString = ""
        var surveyLogMessageList: [Research_SurveyEvent] = []
        let sorted = AppDelegate.emaLog!.sorted(by: {$0.value[1] < $1.value[1]})
        let keyList = sorted.map { (key, value) in (key)}
        //print("keyList = \(keyList)")
        let last = keyList.last!
        for key in keyList{
            //print("\(AppDelegate.homeInstance.getNotificaitonList())")
            //If the key is not a currently displayed notification, not currently about to be chained, and not in progress.
            if !AppDelegate.homeInstance.getNotificaitonList().contains(key) && !HomeVC.currentEMAIdents.contains(key) && AppDelegate.homeInstance.currentEMAIdent != key {
                /*
                buildString += "\(key)"
                for listItem in AppDelegate.emaLog![key]!{
                    buildString += ", \(listItem)"
                }
                */
                let surveyLogProtoBuf = Research_SurveyEvent.with {
                    $0.uuid = key
                    $0.type = AppDelegate.emaLog?[key]?[0] ?? "error"
                    $0.timestamp = Int64(AppDelegate.emaLog?[key]?[1] ?? "0")!
                    $0.intendedDeliveryTime = Int64(AppDelegate.emaLog?[key]?[2] ?? "0")!
                }
                surveyLogMessageList.append(surveyLogProtoBuf)
                AppDelegate.emaLog?.removeValue(forKey: key)
                if last == key{
                    let dataStorage = DataStorage()
                    dataStorage.writeFileProto(dataType: self.emaLogDataString, messageArray: surveyLogMessageList)
                    EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
                }
            }else{
                if last == key{
                    if surveyLogMessageList.count == 0{
                        return
                    }
                    let dataStorage = DataStorage()
                    dataStorage.writeFileProto(dataType: self.emaLogDataString, messageArray: surveyLogMessageList)
                    EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
                }
            }
        }
        
    }
    
    
    
}

