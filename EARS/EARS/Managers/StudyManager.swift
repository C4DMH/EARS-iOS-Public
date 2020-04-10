//
//  StudyManager.swift
//  EARS
//
//  Created by Wyatt Reed on 11/27/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation

class StudyManager{
    //Gotta love the gregorian Calendar
    let weekDayDict = [2:"Mon",3:"Tue",4:"Wed",5:"Thu",6:"Fri",7:"Sat",1:"Sun"]
    let sensorList = ["accel","battery","ema","gps","keyboard","music","selfie", "call", "risk_ema"]
    
    var study: String = ""
    var requestedSensors = [String]()
    var emaMoodIdentifiers = [String]()
    var includedSensors = [String:Bool]()
    var emaPhaseFrequency: Int = -1
    var phaseAutoScheduled = false
    var emaPhaseBreak: Int = -1
    var emaHoursBetween: Int = -1
    var emaWeekDays = [String]()
    var emaDailyStart: String = ""
    var emaDailyEnd: String? = ""
    var emaVariesDuringWeek = false
    var emaWeekDay = [String:[String:String]]()
    
    var emaPhaseStart: Int64? = -1
    var emaPhaseEnd: Int64? = -1
    
    var customizedIntensiveEMA = false
    var customizedDailyEMA = false
    var customDailyEMADeliveryTime = ""
    var customDailyEMAExpirationTime = ""
    var customziedRiskEMA = false
    var customIntensiveExpiration: Int = 0
    
    init(){
        
        
        
    }
    func setVariables(studyName: String){
        self.study = studyName
        self.setCustomStudyVars(studyName: studyName)
        //print("\(AppDelegate.studyDict)")
        self.emaPhaseFrequency = AppDelegate.studyDict["emaPhaseFrequency"] as! Int
        self.requestedSensors = (AppDelegate.studyDict["includedSensors"] as? [String])!
        self.requestedSensors.sort()
        AppDelegate.s3BucketName = AppDelegate.studyDict["s3BucketName"] as! String
        for sensor in self.sensorList{
            self.includedSensors[sensor] = self.requestedSensors.contains(sensor)
        }
        if self.requestedSensors.contains("accel"){
            self.includedSensors["motion_activity"] = true
        }else{
            self.includedSensors["motion_activity"] = false
        }
        //print("\(self.includedSensors)")
        
        self.emaMoodIdentifiers = (AppDelegate.studyDict["emaMoodIdentifiers"] as? [String])!
        
        self.emaHoursBetween = AppDelegate.studyDict["emaHoursBetween"] as! Int
        self.emaWeekDays = (AppDelegate.studyDict["emaWeekDays"] as? [String])!
        
        self.phaseAutoScheduled = AppDelegate.studyDict["phaseAutoScheduled"] as! Bool
        
        if self.phaseAutoScheduled{
            self.emaPhaseBreak = AppDelegate.studyDict["emaPhaseBreak"] as! Int
        }
        
        self.emaVariesDuringWeek = AppDelegate.studyDict["emaVariesDuringWeek"] as! Bool
        
        if self.emaVariesDuringWeek{
            self.emaWeekDay = (AppDelegate.studyDict["emaWeekDay"] as? [String : [String : String]])!
            self.setDailySchedule()
        }else{
            self.emaDailyStart = (AppDelegate.studyDict["emaDailyStart"] as? String)!
            self.emaDailyEnd = AppDelegate.studyDict["emaDailyEnd"] as? String
        }
    }
    //Run before checking the EMA schedule parameters
    func setDailySchedule(){
        if self.emaVariesDuringWeek{
            let currentDateTime = Date()
            let myCalendar = Calendar(identifier: .gregorian)
            let weekDay = myCalendar.component(.weekday, from: currentDateTime)
            //print("weekDay:\(weekDay)")
            
            let schedule = self.emaWeekDay[weekDayDict[weekDay]!]
            
            self.emaDailyStart = schedule!["emaDailyStart"]!
            self.emaDailyEnd = schedule!["emaDailyEnd"]
        }else{
            //NSLog("Unable to set dailySchedule start/end times, ema does not vary by week for \(self.study) study.")
        }
       
    }
    //Run before checking the EMA schedule parameters
    func getDailyStart(for date: Date) -> String {
        if self.emaVariesDuringWeek{
            let currentDateTime = date
            let myCalendar = Calendar(identifier: .gregorian)
            let weekDay = myCalendar.component(.weekday, from: currentDateTime)
            //print("weekDay:\(weekDay)")
            
            let schedule = self.emaWeekDay[weekDayDict[weekDay]!]
            
            return schedule!["emaDailyStart"]!
            //self.emaDailyEnd = schedule!["emaDailyEnd"]
        }else{
            return AppDelegate.study!.emaDailyStart
        }
    }
    
    func getDailyEnd(for date: Date) -> String {
        if self.emaVariesDuringWeek{
            let currentDateTime = date
            let myCalendar = Calendar(identifier: .gregorian)
            let weekDay = myCalendar.component(.weekday, from: currentDateTime)
            //print("weekDay:\(weekDay)")
            
            let schedule = self.emaWeekDay[weekDayDict[weekDay]!]
            
            //return schedule!["emaDailyStart"]!
            return schedule!["emaDailyEnd"]!
        }else{
            return AppDelegate.study!.emaDailyEnd!
        }
    }

    
    func setNextEMAPhaseTuple() -> [Date]{
        //if emaPhaseBreak is defined, we're assuming that emaAutoScheduled is true.
        var now = false
        //Check if there isn't a break between EMAs

        if AppDelegate.study?.emaPhaseBreak == nil{
            //Check If the next EMA phase is to be auto executed:

            if (AppDelegate.study?.phaseAutoScheduled)!{
                //If EMA phase is auto scheduled with no break, assume weekly EMA is continuous
                //return current Date to invoke getEMAPhase on next check
                now = true
            }
        }
        //Execute if there is a break between EMAs
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        

        if now {
            //Set next phase start immediately
            let dateString = dateFormatter.string(from: currentDateTime)
            dateFormatter.dateFormat = "ZZZZZ"
            let timeZoneString = dateFormatter.string(from: currentDateTime)
            //print(dateString)
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            let target = dateString + "00:00:00" + timeZoneString
            let targetDateTime = dateFormatter.date(from: target)
            let targetPhaseEnd = Calendar.current.date(byAdding: .day, value: (AppDelegate.study?.emaPhaseFrequency)! + 1, to: targetDateTime!)!
            AppDelegate.phaseStart = targetDateTime
            AppDelegate.phaseEnd = targetPhaseEnd
            return [targetDateTime!,targetPhaseEnd]
        }
        //Set next phase start one phaseBreak away from the last phaseEnd
        let dateString = dateFormatter.string(from: AppDelegate.phaseEnd!)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let target = dateString + "00:00:00" + timeZoneString
        let targetDateTime = dateFormatter.date(from: target)
        let targetPhaseStart = Calendar.current.date(byAdding: .day, value: (AppDelegate.study?.emaPhaseBreak)!, to: targetDateTime!)
        let targetPhaseEnd = Calendar.current.date(byAdding: .day, value: (AppDelegate.study?.emaPhaseFrequency)! + 1, to: targetPhaseStart!)!
        AppDelegate.phaseStart = targetPhaseStart
        AppDelegate.phaseEnd = targetPhaseEnd
        return [targetPhaseStart!, targetPhaseEnd]
    }
    
    
    func setEMAPhaseEnd() -> Date{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        //let date = dateFormatter.date(from: )
        //dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        //print(dateString)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let target = dateString + "00:00:00" + timeZoneString
        var targetDateTime = dateFormatter.date(from: target)
        
        targetDateTime = Calendar.current.date(byAdding: .day, value: (AppDelegate.study?.emaPhaseFrequency)! + 1, to: targetDateTime!)
        return targetDateTime!
    }
    
    func getEMAPhaseStartTuple() -> [Date]{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        //let date = dateFormatter.date(from: )
        //dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        //print(dateString)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let target = dateString + "00:00:00" + timeZoneString
        let targetDateTime = dateFormatter.date(from: target)
        
        let targetPhaseEnd = Calendar.current.date(byAdding: .day, value: (AppDelegate.study?.emaPhaseFrequency)! + 1, to: targetDateTime!)!
        return [targetDateTime!, targetPhaseEnd]
    }
    
    func parseNSArrayToString(question: Any?) -> String{
        var answer = "\(question ?? "(nil)")"
        answer = answer.replacingOccurrences(of: " ", with: "")
        answer = answer.replacingOccurrences(of: "\n", with: "")
        answer = answer.replacingOccurrences(of: "\"", with: "")
        
        answer.removeFirst()
        answer.removeLast()
        
        return answer
    }
    
    func pullStudyVariables(study: String){
        
        var failed = false
        var final:[String:Any] = [:]
        
        //Create deadlock before checking if request was successful.
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async{
            var request = URLRequest(url: /* REDACTED */)! as URL)

            request.httpMethod = "" //REDACTED
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    NSLog("error=\(String(describing: error))")
                    failed = true
                    group.leave()
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    NSLog("statusCode should be 200, but is \(httpStatus.statusCode)")
                    failed = true
                    group.leave()
                    return
                    
                }
                
                var responseString = String(data: data, encoding: .utf8)
                responseString = "[\(responseString!)]"
                let data2 = responseString!.data(using: .utf8)!
                do {
 
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data2, options : .allowFragments) as? [Dictionary<String,Any>]
                    let keys = jsonSerialized![0].keys
                    var jsonDict:[String:Any] = [:]
                    var emaWeekDays:[String] = []
                    for key in keys{
                        let str = "\(jsonSerialized![0][key]!)"
                        //might be a little hackish, but it works 🤷‍♂️
                        if str.contains("("){
                            jsonDict[key] = (jsonSerialized![0][key]!)
                            if key == "emaWeekDays"{
                                let array = (jsonSerialized![0]["emaWeekDays"]! as! NSArray).mutableCopy() as! NSMutableArray
                                for each in array{
                                    emaWeekDays.append("\(each)")
                                }
                            }
                        }else{
                            final[key] = jsonSerialized![0][key]!
                        }
                    }
                    for key in jsonDict.keys{
                        var tempList:[String] = []
                        if key == "emaWeekDay"{
                            var tempDict:[String:[String:String]] = [:]
                            for each in emaWeekDays{
                                let array = (jsonDict[key] as! NSArray).mutableCopy() as! NSMutableArray
                                let weekday = (array.value(forKey: each) as! NSArray).mutableCopy() as! NSMutableArray
                                let start =  weekday.value(forKey: "emaDailyStart")
                                let end   =  weekday.value(forKey: "emaDailyEnd")
                                let start_string = self.parseNSArrayToString(question: start)
                                let end_string = self.parseNSArrayToString(question: end)
                                
                                tempDict[ each ] = ["emaDailyStart":start_string , "emaDailyEnd" : end_string]
                            }
                            //print("\(tempDict)")
                            final[key] = tempDict
                            //emaWeekDayDict = tempDict
                        }else{
                            
                            let array = (jsonSerialized![0][key]! as! NSArray).mutableCopy() as! NSMutableArray
                            for each in array{
                                tempList.append("\(each)")
                            }
                            final[key] = tempList
                        }
                    }
                } catch let error as NSError {
                    NSLog(error.localizedDescription)
                }
                group.leave()
                
            }
            task.resume()
        }
        
        group.notify(queue: .main) {
            //print("notify")
            if !failed{
                EarsService.shared.setStudyVariables(studyDict: final)
                AppDelegate.studyDict = final
                self.setVariables(studyName: study)
            }
        }
        //self.groupT.leave()
    }
    
    private func setCustomStudyVars(studyName: String){
        switch studyName.lowercased() {
        //truly a placeholder
        case "REDACTED":
            //REDACTED
        default:
            customizedIntensiveEMA = false
            customizedDailyEMA = false
            customziedRiskEMA = false
            customDailyEMADeliveryTime = ""
        }
    }
    func startIntensiveEMA(ident: String){
        switch self.study.lowercased() {
        //truly a placeholder
        case "REDACTED":
            //REDACTED
        default:
            AppDelegate.homeInstance.startSurvey(identifier: ident)
        }
    }
    
    func startDailyEMA(ident: String){
        switch self.study.lowercased() {
        //truly a placeholder
        case "REDACTED":
            //REDACTED
        default:
            AppDelegate.homeInstance.startDailyEMASurvey(identifier: ident)
        }
    }
    
    func startRiskEMA(ident: String){
        switch self.study.lowercased() {
        //truly a placeholder
        case "REDACTED":
            //REDACTED
            AppDelegate.homeInstance.startRiskEMASurvey(identifier: ident)
        default:
            NSLog("error, study should not have risk EMA")
        }
    }
    
    func getCustomEMANotificationTextTitle(type: String) -> String{
        switch type {
        case "daily":
            switch AppDelegate.study?.study.lowercased() {
            //truly a placeholder
            case "REDACTED":
                //REDACTED
            default:
                return "dailyEMATitle".localized()
            }
        case "intensive":
            //truly a placeholder
            case "REDACTED":
                //REDACTED
            default:
                return "EMATitle".localized()
            }
        default:
            return "EMATitle".localized()
        }
    }
    
    func getCustomEMANotificationTextBody(type: String) -> String{
        switch type {
        case "daily":
            switch AppDelegate.study?.study.lowercased() {
            //truly a placeholder
            case "REDACTED":
                //REDACTED
            default:
                return "dailyEMAMessage".localized()
            }
        case "intensive":
            switch AppDelegate.study?.study.lowercased() {
            //truly a placeholder
            case "REDACTED":
                //REDACTED
            default:
                return "EMAMessage".localized()
            }
        default:
            return "EMAMessage".localized()
        }
    }
    

}
