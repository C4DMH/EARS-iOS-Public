//
//  HomeVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/10/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import AMXFontAutoScale
import UIKit
import CoreData
import MediaPlayer
import Reachability
import UserNotifications
import ResearchKit
import Photos
import Firebase
import PopupDialog

class HomeVC: UIViewController, UNUserNotificationCenterDelegate, ORKTaskViewControllerDelegate{
    
    //static var deliveryTime: Int64!
    static var initiatedCurrentEMA: Int64!
    private var expandingTVC: ExpandingTVC!
    
    var sensorsVC: SensorsVC!
    var bat: BatteryManager?
    
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var earsImage: UIImageView!
    @IBOutlet weak var earsIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    var needToTalkTextView: UITextView!
    
    
    let dateFormatter = DateFormatter()
    let gradient      = CAGradientLayer()
    var gradientSet   = [[CGColor]]()
    let gradientOne   = #colorLiteral(red: 0, green: 0.4588235294, blue: 0.8823529412, alpha: 1).cgColor
    let gradientTwo   = #colorLiteral(red: 0.07058823529, green: 0.2156862745, blue: 0.4470588235, alpha: 1).cgColor
    let gradientThree = #colorLiteral(red: 0.03137254902, green: 0.7450980392, blue: 0.8470588235, alpha: 1).cgColor
    
    var currentGradient: Int = 0
    var lastDelivery: Int64  = 0
    var currentEMAIdent = ""
    //var REDACTED : REDACTED?
    //var REDACTED : REDACTED?
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //reschedule EMAs if TimeZone has changed.
        if AppDelegate.updateTimeZone {
            //NSLog("removing scheduled EMAs")
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            AppDelegate.lastScheduledEMADatetime = 0
            AppDelegate.lastScheduledDailyEMADatetime = 0
            AppDelegate.lastScheduledRiskEMADatetime = 0
            AppDelegate.updateTimeZone = false
        }
        
        //run study specific startup tasks
        switch AppDelegate.study?.study {
        case "REDACTED":
             /* REDACTED */
        default:
            //No Custom Study
            AppDelegate.gameEnabled = true
            self.rankBar.setProgress(Float(AppDelegate.emaXP) / Float(self.getXPTotalForRank(newEMARank: Int(AppDelegate.emaRank))), animated: false)
            updateEMAScore()
        }
        
        if #available(iOS 13.0, *) {
            //pass
        }else{
            infoButton.setTitle("i", for: .normal)
        }
        
        //setup accel collection
        if (AppDelegate.study?.includedSensors["accel"])! {
            if CMSensorRecorder.isAccelerometerRecordingAvailable() {
                let recorder = CMSensorRecorder()
                let queue = DispatchQueue(label: "record_accel_viewDidLoad")
                queue.async {
                    recorder.recordAccelerometer(forDuration: 60 * 60 * 12)  // Record for 12 hours
                }
                //print("\(AppDelegate.lastMotionCollection)")
                if AppDelegate.lastMotionCollection == 0{
                    let currentDateTime = Date()
                    AppDelegate.lastMotionCollection = Int64(currentDateTime.timeIntervalSince1970 * 1000)
                    EarsService.shared.setLastMotionCollection(newValue: Int64(currentDateTime.timeIntervalSince1970 * 1000))
                }
            }
            if CMMotionActivityManager.isActivityAvailable(){
                if AppDelegate.lastMotionActivityCollection == 0{
                    let currentDateTime = Date()
                    AppDelegate.lastMotionActivityCollection = Int64(currentDateTime.timeIntervalSince1970 * 1000)
                    EarsService.shared.setLastMotionActivityCollection(newValue: Int64(currentDateTime.timeIntervalSince1970 * 1000))
                }
            }
        }

        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        
        if AppDelegate.homeInstance == nil{
            AppDelegate.homeInstance = self as HomeVC
        }
 
        //setup gps collection (required for background execution access)
        if (AppDelegate.gps.locationEnabled()) {
            if #available(iOS 9.0, *) {
                AppDelegate.gps.locationManager.allowsBackgroundLocationUpdates = true
                AppDelegate.gps.locationManager.pausesLocationUpdatesAutomatically = false
            }
        }
        
        //setup music collection
        if (AppDelegate.study?.includedSensors["music"])!{
            MPMediaLibrary.authorizationStatus()
            AppDelegate.mus = MusicManager()
            NotificationCenter.default.addObserver(self, selector:#selector(getNowPlayingItem), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        }
        
        //setup battery state collection
        if (AppDelegate.study?.includedSensors["battery"])!{
            bat = BatteryManager()
            NotificationCenter.default.addObserver(self, selector: #selector(localBatteryStateDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
            //Uncomment below to get notifications when battery level changes.
            //NotificationCenter.default.addObserver(self, selector: #selector(localBatteryChargeDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        }
    }

    // MARK: userNotificationCenter - UNNotification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.categoryIdentifier == "DailyEMANotification"{
            getMostRecentDeliveredDaily(currentNotification: notification, completion: { (success) in
                if self.checkValidDailyEMA(for: success.date){
                    AppDelegate.study?.startDailyEMA(ident: success.request.identifier)
                    //self.startDailyEMASurvey(identifier: success.request.identifier)
                }else{
                    self.presentInvalidEMADialog()
                }

            })
        }
        if notification.request.content.categoryIdentifier == "RiskEMANotification"{
            getMostRecentDeliveredRisk(currentNotification: notification, completion: { (success) in
                if self.checkRiskEMAStart() && AppDelegate.itIsWednesday(){
                    AppDelegate.study?.startRiskEMA(ident: success.request.identifier)
                    //self.startRiskEMASurvey(identifier: success.request.identifier)
                }else{
                    self.presentInvalidEMADialog()
                }

            })
        }
        if notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
            getMostRecentDelivered(currentNotification: notification, completion: { (success) in
                if self.checkValidEMA(for: success.date){
                    AppDelegate.study?.startIntensiveEMA(ident: success.request.identifier)
                    //self.startSurvey(identifier: success.request.identifier)
                }else{
                    self.presentInvalidEMADialog()
                }

            })
        }
        
    }
    
    // MARK: userNotificationCenter - UNNotificationResponse
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        if response.notification.request.content.categoryIdentifier == "DailyEMANotification"{
            getMostRecentDeliveredDaily(currentNotification: response.notification, completion: { (success) in
                if self.checkValidDailyEMA(for: success.date){
                    AppDelegate.study?.startDailyEMA(ident: success.request.identifier)
                    //self.startDailyEMASurvey(identifier: success.request.identifier)
                }else{
                    self.presentInvalidEMADialog()
                }

            })
        }
        if response.notification.request.content.categoryIdentifier == "RiskEMANotification"{
            getMostRecentDeliveredRisk(currentNotification: response.notification, completion: { (success) in
                if self.checkRiskEMAStart() && AppDelegate.itIsWednesday(){
                    AppDelegate.study?.startRiskEMA(ident: success.request.identifier)
                    //self.startRiskEMASurvey(identifier: success.request.identifier)
                }else{
                    self.presentInvalidEMADialog()
                }

            })
        }
        if response.notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
            getMostRecentDelivered(currentNotification: response.notification, completion: { (success) in
                if self.checkValidEMA(for: success.date){
                    AppDelegate.study?.startIntensiveEMA(ident: success.request.identifier)
                    //self.startSurvey(identifier: success.request.identifier)
                }else{
                    self.presentInvalidEMADialog()
                }
            })
        }
        
    }
    // MARK: getPendingNotificationCount
    func getPendingNotificationCount(completion: @escaping (_ success: Int) -> Void){
        var count = 0
        let group = DispatchGroup()
        
        DispatchQueue.global().async {
            group.enter()
            self.getPending() { (success) -> Void in
                count += success
                group.leave()
            }
            group.wait()
            //Uncomement below to get delivered notifications in the total.
            /*
            group.enter()
            self.getDelivered() { (success) -> Void in
                count += success
                group.leave()
            }
            group.wait()
            */
            completion(count)
        }
        
    }
    // MARK: checkValidEMA
    func checkValidEMA(for date:Date) -> Bool{
        let currentWindowEnd   = roundUpHour()
        //print("currentWindowEnd: \(self.printTimezoneDate(date: currentWindowEnd))")
        let currentWindowStart = Calendar.current.date(byAdding: .hour, value: -2, to: currentWindowEnd)
        //print("windowStart \(currentWindowStart)")
    

        if currentWindowStart! <= date && date <= currentWindowEnd{
            return true
        }else{
            return false
        }
    }
    
    
    // MARK: checkValidDailyEMA
    func checkValidDailyEMA(for date:Date) -> Bool{
        //let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: Date())
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: Date())
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let dailyStart: String
        if (AppDelegate.study?.customDailyEMADeliveryTime.count)! > 0{
            dailyStart = dateString + AppDelegate.study!.customDailyEMADeliveryTime + timeZoneString
        }else{
            dailyStart = dateString + "08:00:00" + timeZoneString
        }
        let dailyEnd = dateString + "23:59:59" + timeZoneString //1 second before Midnight
        let startTarget = dateFormatter.date(from: dailyStart)
        let endTarget = dateFormatter.date(from: dailyEnd)

        //print("windowStart \(currentWindowStart)")

        if startTarget! <= date && date <= endTarget!{
            return true
        }else{
            return false
        }
    }
    // MARK: getPending
    func getPending(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests(completionHandler: { requests in
                completion(requests.count)
            })
    }
    // MARK: getPendingIntensive
    func getPendingIntensive(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests(completionHandler: { requests in
                let scheduledNotifications = requests.filter{$0.content.categoryIdentifier == "ScheduledEMANotification"}
                completion(scheduledNotifications.count)
            })
    }
    // MARK: getPendingDaily
    func getPendingDaily(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests(completionHandler: { requests in
                let scheduledNotifications = requests.filter{$0.content.categoryIdentifier == "DailyEMANotification"}
                completion(scheduledNotifications.count)
            })
    }
    // MARK: getPendingRisk
    func getPendingRisk(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests(completionHandler: { requests in
                let scheduledNotifications = requests.filter{$0.content.categoryIdentifier == "RiskEMANotification"}
                completion(scheduledNotifications.count)
            })
    }
    // MARK: getDelivered
    func getDelivered(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: { notifications in
            completion(notifications.count)
        })
    }
    // MARK: getDeliveredIntensive
    func getDeliveredIntensive(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "ScheduledEMANotification"}
            completion(scheduledNotifications.count)
        })
    }
    // MARK: getDeliveredDaily
    func getDeliveredDaily(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "DailyEMANotification"}
            completion(scheduledNotifications.count)
        })
    }
    // MARK: getDeliveredRisk
    func getDeliveredRisk(completion: @escaping (_ success: Int) -> Void){
        
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "RiskEMANotification"}
            completion(scheduledNotifications.count)
        })
    }
    // MARK: getMostRecentDelivered
    func getMostRecentDelivered(currentNotification: UNNotification, completion: @escaping (_ success: UNNotification) -> Void){
        
        let center = UNUserNotificationCenter.current()
        var recent = currentNotification
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "ScheduledEMANotification"}

            if scheduledNotifications.count == 0 {
                completion(recent)
                return
            }
            var i = 0

            for notification in scheduledNotifications {
                
                if notification.date > recent.date{
                    recent = notification
                }

                i += 1
                if scheduledNotifications.count == i{
                    let removeList = scheduledNotifications.map{$0.request.identifier}
                    //let dateList = scheduledNotifications.map{$0.date}
                    center.removeDeliveredNotifications(withIdentifiers: removeList)
                    completion(recent)
                    return
                }
            }
            //print("nothing happened")
            
        })
    }
    // MARK: getMostRecentDeliveredDaily
    func getMostRecentDeliveredDaily(currentNotification: UNNotification, completion: @escaping (_ success: UNNotification) -> Void){
        
        let center = UNUserNotificationCenter.current()
        var recent = currentNotification
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "DailyEMANotification"}

            if scheduledNotifications.count == 0 {
                completion(recent)
                return
            }
            var i = 0

            for notification in scheduledNotifications {
                
                if notification.date > recent.date{
                    recent = notification
                }

                i += 1
                if scheduledNotifications.count == i{
                    let removeList = scheduledNotifications.map{$0.request.identifier}
                    //let dateList = scheduledNotifications.map{$0.date}
                    center.removeDeliveredNotifications(withIdentifiers: removeList)
                    completion(recent)
                    return
                }
            }
            //print("nothing happened")
            
        })
    }
    // MARK: getMostRecentDeliveredRisk
    func getMostRecentDeliveredRisk(currentNotification: UNNotification, completion: @escaping (_ success: UNNotification) -> Void){
        
        let center = UNUserNotificationCenter.current()
        var recent = currentNotification
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "RiskEMANotification"}

            if scheduledNotifications.count == 0 {
                completion(recent)
                return
            }
            var i = 0

            for notification in scheduledNotifications {
                
                if notification.date > recent.date{
                    recent = notification
                }

                i += 1
                if scheduledNotifications.count == i{
                    let removeList = scheduledNotifications.map{$0.request.identifier}
                    //let dateList = scheduledNotifications.map{$0.date}
                    center.removeDeliveredNotifications(withIdentifiers: removeList)
                    completion(recent)
                    return
                }
            }
            //print("nothing happened")
            
        })
    }
    // MARK: batchScheduleEMA
    func batchScheduleEMA(completion: @escaping (_ success: Bool) -> Void){

        //Pull current number of pending notifications.
        getPendingIntensive(){ (success) -> Void in
            var last: Date
            var next: Date
            var emaScheduleCount = success
            let maxEMACount = 55
            //if EMA not included in the study, skip this nonsense
            if !(AppDelegate.study?.includedSensors["ema"])!{
                completion(true)
                return
            }
            
            if emaScheduleCount >= maxEMACount{
                completion(true)
                return
            }
            
            if AppDelegate.lastScheduledEMADatetime == 0{
                //First time running, set to current time
                last = Calendar.current.date(byAdding: .hour, value: -2, to: self.roundUpHour())!
                
            }else{
                //Pull last saved time interval
                last = Date(timeIntervalSince1970: Double(AppDelegate.lastScheduledEMADatetime / 1000))
                
                // If last is within the phase but still older than the current time, start this hour.
                if AppDelegate.phaseStart! < last && last < AppDelegate.phaseEnd! && last < Date(){
                    last = self.roundUpHour()
                }
                // If the phase is updated and last < the start of the phase
                if last < AppDelegate.phaseStart!{
                    //if the current date is within the bounds of the phase start and end, start doing EMA's again
                    if Date() >= AppDelegate.phaseStart! && Date() <= AppDelegate.phaseEnd!{
                        last = self.roundUpHour()
                    }else{
                        last = AppDelegate.homeInstance.getDayStart(with: AppDelegate.phaseStart!)
                    }
                }
                //print("saved last schedule is: \(self.printTimezoneDate(date: last))")
            }
            //Check if EMA Phase is over.
            if AppDelegate.phaseEnd! <= last {
                //print("EMA Schedule fully booked.")
                completion(true)
                return
                
            }
            
            //Check if where we left off is within our window
            if self.checkEMAWindowForDatetime(date: last){
                //print("last: \(self.printTimezoneDate(date: last))")
                self.sendSingleEMANotification(with: last)
                emaScheduleCount += 1
                //print("emaScheduleCount: \(emaScheduleCount)")
            }else{
                if self.checkIfBeforeDailyStart(date: last){
                    last = self.getDailyStart(with:last)
                    //print("jumped to day start, next: \(self.printTimezoneDate(date: last))")
                    //check if this date is outside the EMA Phase
                    if AppDelegate.phaseEnd! <= last {
                        //print("EMA Schedule fully booked.")
                        EarsService.shared.setLastScheduledEMADatetime(newValue: (Int64(last.timeIntervalSince1970 * 1000)))
                        AppDelegate.lastScheduledEMADatetime = Int64(last.timeIntervalSince1970 * 1000)
                        completion(true)
                        return
                        
                    }else{
                        if self.checkEMAWindowForDatetime(date: last){
                            self.sendSingleEMANotification(with: last)
                            emaScheduleCount += 1
                            //print("emaScheduleCount: \(emaScheduleCount)")
                        }
                        
                    }
                }else{
                    //if not within our window, try the next day at applicable start time.
                    last = self.getNextDayStart(with: last)
                    //print("new day, next: \(self.printTimezoneDate(date: last))")
                    //check if this date is outside the EMA Phase
                    if AppDelegate.phaseEnd! <= last {
                        //print("EMA Schedule fully booked.")
                        EarsService.shared.setLastScheduledEMADatetime(newValue: (Int64(last.timeIntervalSince1970 * 1000)))
                        AppDelegate.lastScheduledEMADatetime = Int64(last.timeIntervalSince1970 * 1000)
                        completion(true)
                        return
                        
                    }else{
                        if self.checkEMAWindowForDatetime(date: last){
                            self.sendSingleEMANotification(with: last)
                            emaScheduleCount += 1
                            //print("emaScheduleCount: \(emaScheduleCount)")
                        }
                        
                    }
                }
            }
            
            //Send first EMA
            
            next = self.getIntervalRangeDate(with: last)
            //print("next: \(self.printTimezoneDate(date: next))")
            while emaScheduleCount < maxEMACount{
                if AppDelegate.phaseEnd! <= next {
                    //print("EMA Schedule fully booked.")
                    EarsService.shared.setLastScheduledEMADatetime(newValue: (Int64(next.timeIntervalSince1970 * 1000)))
                    AppDelegate.lastScheduledEMADatetime = Int64(next.timeIntervalSince1970 * 1000)
                    completion(true)
                    return
                    
                }
                if self.checkEMAWindowForDatetime(date: next){
                    //print("next: \(self.printTimezoneDate(date: next))")
                    self.sendSingleEMANotification(with: next)
                    emaScheduleCount += 1
                }else{
                    
                    next = self.getNextDayStart(with: next)
                    //print("new day, next: \(self.printTimezoneDate(date: next))")
                    if AppDelegate.phaseEnd! <= next {
                        //print("Intense EMA Schedule fully booked.")
                        EarsService.shared.setLastScheduledEMADatetime(newValue: (Int64(next.timeIntervalSince1970 * 1000)))
                        AppDelegate.lastScheduledEMADatetime = Int64(next.timeIntervalSince1970 * 1000)
                        completion(true)
                        return
                        
                    }else{
                        if self.checkEMAWindowForDatetime(date: next){
                            self.sendSingleEMANotification(with: next)
                            emaScheduleCount += 1
                        }
                    }
                }
                
                //print("emaScheduleCount: \(emaScheduleCount)")
                if emaScheduleCount == maxEMACount {
                    EarsService.shared.setLastScheduledEMADatetime(newValue: (Int64(self.getIntervalRangeDate(with: next).timeIntervalSince1970 * 1000)))
                    AppDelegate.lastScheduledEMADatetime = Int64(self.getIntervalRangeDate(with: next).timeIntervalSince1970 * 1000)
                    completion(true)
                    return
                    
                }else{
                    next = self.getIntervalRangeDate(with: next)
                    //print("nxt: \(self.printTimezoneDate(date: next))")
                }
            }
            //print("EMA Schedule maxed at 62")
            if emaScheduleCount == maxEMACount {
                EarsService.shared.setLastScheduledEMADatetime(newValue: (Int64(self.getIntervalRangeDate(with: next).timeIntervalSince1970 * 1000)))
                AppDelegate.lastScheduledEMADatetime = Int64(self.getIntervalRangeDate(with: next).timeIntervalSince1970 * 1000)
                completion(true)
                return
                
            }
        }
        //print("emaScheduleCount: \(emaScheduleCount)")
        
       
    }
    // MARK: ScheduleOneEMADaily
    func ScheduleOneEMADaily(completion: @escaping (_ success: Bool) -> Void){

        //Pull current number of pending notifications.
        getPendingDaily(){ (success) -> Void in
            var last: Date
            var next: Date

            if success == 0{
                last = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
                if !self.checkDailyEMAWindowForDatetime(date: last){
                    last = self.getNextDailyEMA(with: Calendar.current.date(byAdding: .day, value: -1, to: last)!)
                }
                UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                           
                           // we're only going to create and schedule a notification
                           // if the user has kept notifications authorized for this app
                           guard settings.authorizationStatus == .authorized else { return }
                           
                           // create the content and style for the local notification
                           let content = UNMutableNotificationContent()
                           
                           // #2.1 - "Assign a value to this property that matches the identifier
                           // property of one of the UNNotificationCategory objects you
                           // previously registered with your app."
                           content.categoryIdentifier = "DailyEMANotification"
                           
                           // create the notification's content to be presented
                           // to the user
                           content.title = AppDelegate.study!.getCustomEMANotificationTextTitle(type: "daily")
                           content.body  = AppDelegate.study!.getCustomEMANotificationTextBody(type: "daily")
                           content.sound = UNNotificationSound.default
                           
                           
                           // #2.2 - create a "trigger condition that causes a notification
                           // to be delivered after the specified amount of time elapses";
                           // deliver after 10 seconds
                           
                           let time:TimeInterval = last.timeIntervalSinceNow
                           let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
                           
                           
                           // create a "request to schedule a local notification, which
                           // includes the content of the notification and the trigger conditions for delivery"
                           let uuidString = UUID().uuidString
                           let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
                           let scheduledDateTime = String(Int64((Date().timeIntervalSince1970 + time) * 1000))
                           content.userInfo["deliveryTime"] = "\(scheduledDateTime)"
                    
                           let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                           
                           AppDelegate.emaLog![uuidString] = ["Daily","\(currentDateTime)","\(scheduledDateTime)"]
                           EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
                           UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                       }
                next = self.getNextDailyEMA(with: last)
                EarsService.shared.setLastScheduledDailyEMADatetime(newValue: (Int64(next.timeIntervalSince1970 * 1000)))
                AppDelegate.lastScheduledDailyEMADatetime = Int64(next.timeIntervalSince1970 * 1000)
                //print("Daily done: \(self.printTimezoneDate(date: next))")
                completion(true)
                return
                
            }else{
                completion(true)
                return
            }
        }
        
    }
    
    // MARK: batchScheduleEMADaily
    func batchScheduleEMADaily(completion: @escaping (_ success: Bool) -> Void){

        //Pull current number of pending notifications.
        getPendingDaily(){ (success) -> Void in
            var last: Date
            var next: Date
            var emaScheduleCount = success
            let maxEMACount = 6
            //print("dailyEMAScheduleCount: \(emaScheduleCount)")

            if emaScheduleCount >= maxEMACount{
                completion(true)
                return
            }
            
            if AppDelegate.lastScheduledDailyEMADatetime == 0{
                //First time running, set to current time +1 minute
                //last = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
                if AppDelegate.study?.study == "REDACTED"{
                    /* REDACTED */
                }else{
                    last = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
                    //check if within the correct timeframe to deliver daily EMA.
                    if !self.checkDailyEMAWindowForDatetime(date: last){
                        last = self.getNextDailyEMA(with: Calendar.current.date(byAdding: .day, value: -1, to: last)!)
                    }
                }
            }else{
                //Pull last saved time interval
                last = Date(timeIntervalSince1970: Double(AppDelegate.lastScheduledDailyEMADatetime / 1000))
                
                // If last is within the phase but still older than the current time, start this hour.
                // TODO change to check current time.
                if last < Date(){
                    //if the last daily is older than our current time, send now
                    last = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
                    if !self.checkDailyEMAWindowForDatetime(date: last) && AppDelegate.lastDailyEMARecieved != AppDelegate.getDay(){
                        last = self.getNextDailyEMA(with: Calendar.current.date(byAdding: .day, value: -1, to: last)!)
                    }
                }

                //print("saved last schedule is: \(self.printTimezoneDate(date: last))")
            }
            
            //Send first EMA
            print("Daily first: \(self.printTimezoneDate(date: last))")
            self.sendSingleDailyEMANotification(with: last)
            //get next EMA time
            next = self.getNextDailyEMA(with: last)
            //print("Daily next: \(self.printTimezoneDate(date: next))")
            emaScheduleCount += 1
            //print("next: \(self.printTimezoneDate(date: next))")
            while emaScheduleCount < maxEMACount{
                //Send it
                self.sendSingleDailyEMANotification(with: next)
                emaScheduleCount += 1
                //print("emaScheduleCount: \(emaScheduleCount)")
                if emaScheduleCount == maxEMACount {
                    EarsService.shared.setLastScheduledDailyEMADatetime(newValue: (Int64(self.getNextDailyEMA(with: next).timeIntervalSince1970 * 1000)))
                    AppDelegate.lastScheduledDailyEMADatetime = Int64(self.getNextDailyEMA(with: next).timeIntervalSince1970 * 1000)
                    //print("Daily done: \(self.printTimezoneDate(date: self.getNextDailyEMA(with: next)))")
                    completion(true)
                    return
                    
                }else{
                    next = self.getNextDailyEMA(with: next)
                    //print("Daily next: \(self.printTimezoneDate(date: next))")
                }
            }
            //print("EMA Schedule maxed at 7")
            if emaScheduleCount == maxEMACount {
                EarsService.shared.setLastScheduledDailyEMADatetime(newValue: (Int64(next.timeIntervalSince1970 * 1000)))
                AppDelegate.lastScheduledDailyEMADatetime = Int64(next.timeIntervalSince1970 * 1000)
                //print("Daily done: \(self.printTimezoneDate(date: next))")
                completion(true)
                return
                
            }
        }
        //print("emaScheduleCount: \(emaScheduleCount)")
        
    }
    
    func batchScheduleEMARisk(completion: @escaping (_ success: Bool) -> Void){
        if !(AppDelegate.study?.includedSensors["risk_ema"])!{
            completion(true)
            return
        }
        //Pull current number of pending notifications.
        getPendingRisk(){ (success) -> Void in
            var last: Date
            var next: Date
            var emaScheduleCount = success
            let maxEMACount = 2

            if emaScheduleCount >= maxEMACount{
                completion(true)
                return
            }
            
            
            if AppDelegate.lastScheduledRiskEMADatetime == 0{
                //First time running, set to current time +1 minute
                if self.checkRiskEMAStart() && AppDelegate.itIsWednesday() {
                    last = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
                    //print("firsst: \(self.printTimezoneDate(date: last))")
                }else{
                    last = self.getNextRiskEMA(with: Date())
                }

            }else{
                //Pull last saved time interval
                last = Date(timeIntervalSince1970: Double(AppDelegate.lastScheduledRiskEMADatetime / 1000))
                
                // If last is within the phase but still older than the current time, start this hour.
                // TODO change to check current time.
                if last < Date(){
                    //if the last daily is older than our current time, send now
                    last = self.getNextRiskEMA(with: Date())
                }

                //print("saved last schedule is: \(self.printTimezoneDate(date: last))")
            }
            
            //Send first EMA
            self.sendSingleRiskEMANotification(with: last)
            //get next EMA time
            next = self.getNextRiskEMA(with: last)
            //print("nexxt: \(self.printTimezoneDate(date: next))")
            emaScheduleCount += 1
            //print("next: \(self.printTimezoneDate(date: next))")
            while emaScheduleCount < maxEMACount{
                //Send it
                self.sendSingleRiskEMANotification(with: next)
                emaScheduleCount += 1
                //print("emaScheduleCountz: \(emaScheduleCount)")
                if emaScheduleCount == maxEMACount {
                    EarsService.shared.setLastScheduledRiskEMADatetime(newValue: (Int64(self.getNextRiskEMA(with: next).timeIntervalSince1970 * 1000)))
                    AppDelegate.lastScheduledRiskEMADatetime = Int64(self.getNextRiskEMA(with: next).timeIntervalSince1970 * 1000)
                    //print("donee: \(self.printTimezoneDate(date: self.getNextRiskEMA(with: next)))")
                    completion(true)
                    return
                    
                }else{
                    next = self.getNextRiskEMA(with: next)
                    //print("nexxt: \(self.printTimezoneDate(date: next))")
                }
            }
            //print("EMA Schedule maxed at 7")
            if emaScheduleCount == maxEMACount {
                EarsService.shared.setLastScheduledRiskEMADatetime(newValue: (Int64(next.timeIntervalSince1970 * 1000)))
                AppDelegate.lastScheduledRiskEMADatetime = Int64(next.timeIntervalSince1970 * 1000)
                //print("donee: \(self.printTimezoneDate(date: next))")
                completion(true)
                return
                
            }
        }
        //print("emaScheduleCount: \(emaScheduleCount)")
        
        
       
    }
    // MARK: sendSingleEMANotification
    func sendSingleEMANotification(with datetime:Date){
        
        // find out what are the user's notification preferences
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            // we're only going to create and schedule a notification
            // if the user has kept notifications authorized for this app
            guard settings.authorizationStatus == .authorized else { return }
            
            // create the content and style for the local notification
            let content = UNMutableNotificationContent()
            
            // #2.1 - "Assign a value to this property that matches the identifier
            // property of one of the UNNotificationCategory objects you
            // previously registered with your app."
            content.categoryIdentifier = "ScheduledEMANotification"
            
            // create the notification's content to be presented
            // to the user
            content.title = AppDelegate.study!.getCustomEMANotificationTextTitle(type: "intensive")
            content.body  = AppDelegate.study!.getCustomEMANotificationTextBody(type: "intensive")
            content.sound = UNNotificationSound.default
            
            
            
            // #2.2 - create a "trigger condition that causes a notification
            // to be delivered after the specified amount of time elapses";
            // deliver after 10 seconds
            
            let time:TimeInterval = self.getSpecificNotificationInterval(beginInterval: datetime)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
            
            
            // create a "request to schedule a local notification, which
            // includes the content of the notification and the trigger conditions for delivery"
            let uuidString = UUID().uuidString
            let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
            let scheduledDateTime = String(Int64((Date().timeIntervalSince1970 + time) * 1000))
            content.userInfo["deliveryTime"] = "\(scheduledDateTime)"
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

            AppDelegate.emaLog![uuidString] = ["EMA","\(currentDateTime)","\(scheduledDateTime)"]
            //print("\(AppDelegate.emaLog)")
            // "Upon calling this method, the system begins tracking the
            // trigger conditions associated with your request. When the
            // trigger condition is met, the system delivers your notification."
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            //EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
            //completion(true)
            
            
        }
    }
    // MARK: sendSingleDailyEMANotification
    func sendSingleDailyEMANotification(with datetime:Date){
        
        // find out what are the user's notification preferences
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            // we're only going to create and schedule a notification
            // if the user has kept notifications authorized for this app
            guard settings.authorizationStatus == .authorized else { return }
            
            // create the content and style for the local notification
            let content = UNMutableNotificationContent()
            
            // #2.1 - "Assign a value to this property that matches the identifier
            // property of one of the UNNotificationCategory objects you
            // previously registered with your app."
            content.categoryIdentifier = "DailyEMANotification"
            
            // create the notification's content to be presented
            // to the user
            content.title = AppDelegate.study!.getCustomEMANotificationTextTitle(type: "daily")
            content.body  = AppDelegate.study!.getCustomEMANotificationTextBody(type: "daily")
            if AppDelegate.study!.customizedDailyEMA{
                content.body = "\(AppDelegate.study!.study)dailyEMAMessage".localized()
            }
            content.sound = UNNotificationSound.default
            
            
            // #2.2 - create a "trigger condition that causes a notification
            // to be delivered after the specified amount of time elapses";
            // deliver after 10 seconds
            
            let time:TimeInterval = datetime.timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
            
            
            // create a "request to schedule a local notification, which
            // includes the content of the notification and the trigger conditions for delivery"
            let uuidString = UUID().uuidString
            let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
            let scheduledDateTime = String(Int64((Date().timeIntervalSince1970 + time) * 1000))
            content.userInfo["deliveryTime"] = "\(scheduledDateTime)"
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            AppDelegate.emaLog![uuidString] = ["Daily","\(currentDateTime)","\(scheduledDateTime)"]
            //print("\(AppDelegate.emaLog)")
            // "Upon calling this method, the system begins tracking the
            // trigger conditions associated with your request. When the
            // trigger condition is met, the system delivers your notification."
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            //EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
            //completion(true)
            
            
        }
    }
    
    // MARK: sendSingleRiskEMANotification
    func sendSingleRiskEMANotification(with datetime:Date){
        
        // find out what are the user's notification preferences
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            // we're only going to create and schedule a notification
            // if the user has kept notifications authorized for this app
            guard settings.authorizationStatus == .authorized else { return }
            
            // create the content and style for the local notification
            let content = UNMutableNotificationContent()
            
            // #2.1 - "Assign a value to this property that matches the identifier
            // property of one of the UNNotificationCategory objects you
            // previously registered with your app."
            content.categoryIdentifier = "RiskEMANotification"
            
            // create the notification's content to be presented
            // to the user
            content.title = "riskEMATitle".localized()
            content.body = "riskEMAMessage".localized()
            content.sound = UNNotificationSound.default
            
            
            // #2.2 - create a "trigger condition that causes a notification
            // to be delivered after the specified amount of time elapses";
            // deliver after 10 seconds
            
            let time:TimeInterval = datetime.timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
            
            
            // create a "request to schedule a local notification, which
            // includes the content of the notification and the trigger conditions for delivery"
            let uuidString = UUID().uuidString
            let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
            let scheduledDateTime = String(Int64((Date().timeIntervalSince1970 + time) * 1000))
            content.userInfo["deliveryTime"] = "\(scheduledDateTime)"
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            AppDelegate.emaLog![uuidString] = ["RISK","\(currentDateTime)","\(scheduledDateTime)"]
            //print("\(AppDelegate.emaLog)")
            // "Upon calling this method, the system begins tracking the
            // trigger conditions associated with your request. When the
            // trigger condition is met, the system delivers your notification."
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            //EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
            //completion(true)
            
            
        }
    }
    // MARK: getNextDayStart
    func getNextDayStart(with date: Date)-> Date{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: Calendar.current.date(byAdding: .day, value: 1, to: date)!))! + timeZoneString
        //let dailyEnd = dateString + (AppDelegate.study?.emaDailyEnd)! + timeZoneString //1 second before Midnight
        let startTarget = dateFormatter.date(from: dailyStart)
        //let endTarget = dateFormatter.date(from: dailyEnd)
        //last = Calendar.current.date(byAdding: .day, value: 1, to: startTarget!)!
        return Calendar.current.date(byAdding: .day, value: 1, to: startTarget!)!
    }
    
    // MARK: getDailyStart
    func getDailyStart(with date: Date)-> Date{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: date))! + timeZoneString
        let startTarget = dateFormatter.date(from: dailyStart)
        return startTarget!
    }
    
    // MARK: getNextDailyEMA
    func getNextDailyEMA(with date: Date)-> Date{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart: String
        if (AppDelegate.study?.customDailyEMADeliveryTime.count)! > 0{
            dailyStart = dateString + AppDelegate.study!.customDailyEMADeliveryTime + timeZoneString
        }else{
            dailyStart = dateString + "08:00:00" + timeZoneString
        }
        
        //let dailyEnd = dateString + (AppDelegate.study?.emaDailyEnd)! + timeZoneString //1 second before Midnight
        let startTarget = dateFormatter.date(from: dailyStart)
        //let endTarget = dateFormatter.date(from: dailyEnd)
        //last = Calendar.current.date(byAdding: .day, value: 1, to: startTarget!)!
        return Calendar.current.date(byAdding: .day, value: 1, to: startTarget!)!
    }
    
    // MARK: getNextRiskEMA
    func getNextRiskEMA(with date: Date)-> Date{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let dailyStart = dateString + "09:00:00" + timeZoneString
        //let dailyEnd = dateString + (AppDelegate.study?.emaDailyEnd)! + timeZoneString //1 second before Midnight
        let startTarget = dateFormatter.date(from: dailyStart)
        //let endTarget = dateFormatter.date(from: dailyEnd)
        //last = Calendar.current.date(byAdding: .day, value: 1, to: startTarget!)!
        return startTarget!.next(.wednesday)
    }
    
    // MARK: getDayStart
    func getDayStart(with date: Date)-> Date{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: date))! + timeZoneString
        //let dailyEnd = dateString + (AppDelegate.study?.emaDailyEnd)! + timeZoneString //1 second before Midnight
        let startTarget = dateFormatter.date(from: dailyStart)
        //let endTarget = dateFormatter.date(from: dailyEnd)
        //last = Calendar.current.date(byAdding: .day, value: 1, to: startTarget!)!
        return startTarget!
    }
    
    // MARK: printTimezoneDate
    func printTimezoneDate(date: Date)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let timeZoneString = dateFormatter.string(from: date)
        return timeZoneString
    }
    
    // MARK: sendEMANotification
    /// Schedules an EMA notification that will prompt the user to complete an EMA survey with specific timing.
    ///
    /// Citation: (https://github.com/appcoda/iOS-12-Notifications/blob/master/iOS%2012%20Notifications/ViewController.swift)
    func sendEMANotification(completion: @escaping (_ success: Bool) -> Void){
        //AppDelegate.debug.recordLog(line: "sending notification")
        
        let time:TimeInterval = self.getNotificationInterval()
        
        if (AppDelegate.study?.emaVariesDuringWeek)!{
            AppDelegate.study?.setDailySchedule()
        }
        //print("\(AppDelegate.phaseStart) < \(Date()) < \(AppDelegate.phaseEnd)")


        //Check if phase is nil
        if (AppDelegate.phaseStart != nil && AppDelegate.phaseEnd != nil){
            //if phase is set, we check if it's outside the correct range
            if AppDelegate.phaseStart! > Date() || AppDelegate.phaseEnd! < Date(){
                completion(true)
                return
            }
        }else{
            //if phase is not set, we check if it's autoscheduled.
            //If autoscheduled and nil, we continuosly run EMAs
            if !(AppDelegate.study?.phaseAutoScheduled)!{
                completion(true)
                return
            }
        }

        //print("\(AppDelegate.phaseStart) < \(Date()) < \(AppDelegate.phaseEnd)")
        
        if !checkEMAWindow() {
            completion(true)
            return
        }
 
        // find out what are the user's notification preferences
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            // we're only going to create and schedule a notification
            // if the user has kept notifications authorized for this app
            guard settings.authorizationStatus == .authorized else { return }
            
            // create the content and style for the local notification
            let content = UNMutableNotificationContent()
            
            // #2.1 - "Assign a value to this property that matches the identifier
            // property of one of the UNNotificationCategory objects you
            // previously registered with your app."
            content.categoryIdentifier = "ScheduledEMANotification"
            
            // create the notification's content to be presented
            // to the user
            content.title = AppDelegate.study!.getCustomEMANotificationTextTitle(type: "intensive")
            content.body  = AppDelegate.study!.getCustomEMANotificationTextBody(type: "intensive")
            content.sound = UNNotificationSound.default

            
            
            // #2.2 - create a "trigger condition that causes a notification
            // to be delivered after the specified amount of time elapses";
            // deliver after 10 seconds

            //let time:TimeInterval = self.getNotificationInterval()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)

            
            // create a "request to schedule a local notification, which
            // includes the content of the notification and the trigger conditions for delivery"
            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
            let scheduledDateTime = String(Int64((Date().timeIntervalSince1970 + time) * 1000))
            AppDelegate.emaLog![uuidString] = ["EMA","\(currentDateTime)","\(scheduledDateTime)"]
            //print("\(AppDelegate.emaLog)")
            // "Upon calling this method, the system begins tracking the
            // trigger conditions associated with your request. When the
            // trigger condition is met, the system delivers your notification."
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            //EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
            //completion(true)

            
        } // end getNotificationSettings
        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(1), execute: {
            completion(true)
        })
    } // end func sendNotificationButtonTapped
    
    // MARK: sendDailyNotification
    /// Schedules a daily EMA notification with one question. Before starting, the function checks if the daily EMA notification has been sent already today and if its after the initial start time (8:00am.) The daily EMA will clear our previous local notifications with the DailyEMANotification category identifier and then schedule a local notification immediately. Once sent, the daily EMA will not register until the next day.
    ///
    ///Citation: (https://github.com/appcoda/iOS-12-Notifications/blob/master/iOS%2012%20Notifications/ViewController.swift)
    func sendDailyNotification(completion: @escaping (_ success: Bool) -> Void){
        
        if !checkDailyEMAStart(){
            completion(true)
            return
        }
        
        //AppDelegate.debug.recordLog(line: "sending Daily notification")
        let center = UNUserNotificationCenter.current()
        var deliveredRemovalList:[String] = []
        center.getDeliveredNotifications(completionHandler: { notifications in
            for notification in notifications {
                //print(notification.request.content.categoryIdentifier)
                if notification.request.content.categoryIdentifier == "DailyEMANotification" || notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
                    deliveredRemovalList.append(notification.request.identifier)
                    //print(notification.request.identifier)
                }
            }
            center.removeDeliveredNotifications(withIdentifiers: deliveredRemovalList)
        })
        
        // find out what are the user's notification preferences
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            // we're only going to create and schedule a notification
            // if the user has kept notifications authorized for this app
            guard settings.authorizationStatus == .authorized else { return }
            
            // create the content and style for the local notification
            let content = UNMutableNotificationContent()
            
            // #2.1 - "Assign a value to this property that matches the identifier
            // property of one of the UNNotificationCategory objects you
            // previously registered with your app."
            content.categoryIdentifier = "DailyEMANotification"
            
            // create the notification's content to be presented
            // to the user
            content.title = AppDelegate.study!.getCustomEMANotificationTextTitle(type: "daily")
            content.body  = AppDelegate.study!.getCustomEMANotificationTextBody(type: "daily")
            content.sound = UNNotificationSound.default
            
            
            // #2.2 - create a "trigger condition that causes a notification
            // to be delivered after the specified amount of time elapses";
            // deliver after 10 seconds
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)

            // create a "request to schedule a local notification, which
            // includes the content of the notification and the trigger conditions for delivery"
            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
            let scheduledDateTime = String(Int64((Date().timeIntervalSince1970 + 2) * 1000))
            AppDelegate.emaLog![uuidString] = ["Daily","\(currentDateTime)","\(scheduledDateTime)"]
            //print("\(AppDelegate.emaLog)")
            // "Upon calling this method, the system begins tracking the
            // trigger conditions associated with your request. When the
            // trigger condition is met, the system delivers your notification."
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)

            
        } // end getNotificationSettings
        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(1), execute: {
            completion(true)
        })
    } // end func sendNotificationButtonTapped
    
    // MARK: sendRiskNotification
    func sendRiskNotification(completion: @escaping (_ success: Bool) -> Void){
        
        let center = UNUserNotificationCenter.current()
        var deliveredRemovalList:[String] = []
        center.getDeliveredNotifications(completionHandler: { notifications in
            for notification in notifications {
                //print(notification.request.content.categoryIdentifier)
                if notification.request.content.categoryIdentifier == "RiskEMANotification"{
                    deliveredRemovalList.append(notification.request.identifier)
                    //print(notification.request.identifier)
                }
            }
            center.removeDeliveredNotifications(withIdentifiers: deliveredRemovalList)
        })
        
        if !checkRiskEMAStart(){
            completion(true)
            return
        }
        // find out what are the user's notification preferences
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            
            // we're only going to create and schedule a notification
            // if the user has kept notifications authorized for this app
            guard settings.authorizationStatus == .authorized else { return }
            
            // create the content and style for the local notification
            let content = UNMutableNotificationContent()
            
            // #2.1 - "Assign a value to this property that matches the identifier
            // property of one of the UNNotificationCategory objects you
            // previously registered with your app."
            content.categoryIdentifier = "RiskEMANotification"
            
            // create the notification's content to be presented
            // to the user
            content.title = "riskEMATitle".localized()
            content.body = "riskEMAMessage".localized()
            content.sound = UNNotificationSound.default
            
            
            // #2.2 - create a "trigger condition that causes a notification
            // to be delivered after the specified amount of time elapses";
            // deliver after 10 seconds
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // create a "request to schedule a local notification, which
            // includes the content of the notification and the trigger conditions for delivery"
            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
            let scheduledDateTime = String(Int64((Date().timeIntervalSince1970 + 1) * 1000))
            AppDelegate.emaLog![uuidString] = ["RISK","\(currentDateTime)","\(scheduledDateTime)"]
            
            // "Upon calling this method, the system begins tracking the
            // trigger conditions associated with your request. When the
            // trigger condition is met, the system delivers your notification."
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)

            
        } // end getNotificationSettings
        //AppDelegate.debug.recordLog(line: "Notification send sequence complete.")
        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(1), execute: {
            completion(true)
        })
    } // end func sendNotificationButtonTapped
    
    
    // MARK: sendRiskAlert
    /// Makes a web request to AWS so risk EMA can be handled properly.
    ///
    /// - Parameters:
    ///   - deviceID: device ID for install
    ///   - study: current device study
    ///   - values: user answers from risk EMA
    func sendRiskAlert(deviceID: String, study: String, values: [String]){
        //Create deadlock before checking if request was successful.
        let group = DispatchGroup()
        group.enter()
        
        let riskOne = values[0]
        let riskTwo = values[1]
        let riskThree = values[2]
        let riskURLString = "" /* REDACTED */
        
        var alertSuccess = false
        DispatchQueue.main.async{
            
            var request = URLRequest(url: NSURL(string: riskURLString)! as URL)
            request.httpMethod = "" /* REDACTED */
            request.addValue(/* REDACTED */)

            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    NSLog("error=\(String(describing: error))")
                    group.leave()
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    NSLog("statusCode should be 200, but is \(httpStatus.statusCode)")
                    //print("response = \(response!)")
                    
                }else{
                    alertSuccess = true
                }
                
                group.leave()
                
            }
            task.resume()
        }
        
        group.notify(queue: .main) {
            if !alertSuccess{
                EarsService.shared.setRiskURLString(newValue: riskURLString)
                AppDelegate.riskURLString = riskURLString
            }
                
        }
        
    }
    
    // MARK: sendFollowupRiskEMARequest
    /// If the original web request failed due to a connection error, save the URL as a string and pass it to this function.
    ///
    /// - Parameter riskURLString: URL string from previous attempt.
    func sendFollowupRiskEMARequest(riskURLString: String){
        //print("initiating followup risk EMA request.")
        //Create deadlock before checking if request was successful.
        let group = DispatchGroup()
        group.enter()
        
        var alertSuccess = false
        DispatchQueue.main.async{
            
            var request = URLRequest(url: NSURL(string: riskURLString)! as URL)
            request.httpMethod = "" /* REDACTED */
            request.addValue( /* REDACTED */)
            
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    NSLog("error=\(String(describing: error))")
                    group.leave()
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    NSLog("statusCode should be 200, but is \(httpStatus.statusCode)")
                    //print("response = \(response!)")
                    
                }else{
                    alertSuccess = true
                }
                
                let responseString = String(data: data, encoding: .utf8)
                //NSLog("responseString = \(responseString)")
                group.leave()
                
            }
            task.resume()
        }
        
        group.notify(queue: .main) {
            if alertSuccess{
                EarsService.shared.setRiskURLString(newValue: "")
                AppDelegate.riskURLString = ""
            }
            
        }
        
    }
    
    static var currentEMAList:[String] = []
    static var currentEMAIdents:[String] = []
    static var suddenEMA:[String] = []
    static var suddenEMAIdents:[String] = []
    
    // MARK: chainEMAs
    /// Once one EMA notification is opened, prompt the user with other available EMAs.
    func chainEMAs(){
        //let queue = DispatchQueue(label: "SerialQueue")
        let center = UNUserNotificationCenter.current()
        let group = DispatchGroup()
        group.enter()
        
        var studyClaimSuccess = false
        DispatchQueue.main.async{

            if HomeVC.currentEMAList.count == 0 {
                
                center.getDeliveredNotifications(completionHandler: { notifications in
                    for notification in notifications {
                        //print("\(notification.request.content.categoryIdentifier)")
                        //print(notification.request.content.categoryIdentifier)
                        if notification.request.content.categoryIdentifier == "RiskEMANotification"{
                            //deliveredRemovalList.append(notification.request.identifier)
                            if HomeVC.currentEMAList.count > 0{
                                HomeVC.currentEMAList.insert(notification.request.identifier, at: 0)
                                HomeVC.currentEMAIdents.insert(notification.request.content.categoryIdentifier, at: 0)
                            }else{
                                HomeVC.currentEMAList.append(notification.request.identifier)
                                HomeVC.currentEMAIdents.append(notification.request.content.categoryIdentifier)

                            }
                            //print(notification.request.identifier)
                        }
                        if notification.request.content.categoryIdentifier == "DailyEMANotification"{
                            
                            if self.checkValidDailyEMA(for: notification.date){
                                if HomeVC.currentEMAList.count > 0{
                                    HomeVC.currentEMAList.insert(notification.request.identifier, at: 0)
                                    HomeVC.currentEMAIdents.insert(notification.request.content.categoryIdentifier, at: 0)
                                }else{
                                    HomeVC.currentEMAList.append(notification.request.identifier)
                                    HomeVC.currentEMAIdents.append(notification.request.content.categoryIdentifier)
                                }
                            }
                        }
                        if notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
                            
                            HomeVC.currentEMAList.append(notification.request.identifier)
                            HomeVC.currentEMAIdents.append(notification.request.content.categoryIdentifier)
                        }
                    }
                    //center.removeDeliveredNotifications(withIdentifiers: HomeVC.currentEMAList)
                    group.leave()
                })
            }else{
                 group.leave()
            }
        }
        group.notify(queue: .main) {
            //print(HomeVC.currentEMAList.count)
            if HomeVC.currentEMAList.count > 0{
                switch HomeVC.currentEMAIdents[0] {
                case "RiskEMANotification":
                    AppDelegate.study?.startRiskEMA(ident: HomeVC.currentEMAList[0])
                    //self.startRiskEMASurvey(identifier: HomeVC.currentEMAList[0])
                case "DailyEMANotification":
                    AppDelegate.study?.startDailyEMA(ident: HomeVC.currentEMAList[0])
                    //self.startDailyEMASurvey(identifier: HomeVC.currentEMAList[0])
                case "ScheduledEMANotification":
                    AppDelegate.study?.startIntensiveEMA(ident: HomeVC.currentEMAList[0])
                    //self.startSurvey(identifier: HomeVC.currentEMAList[0])
                default:
                    NSLog("error: unexpected EMA Notification identifier in EMA chain.")
                }
                var removeEMA:[String] = []
                let removed = HomeVC.currentEMAList.remove(at: 0)
                removeEMA.append(removed)
                center.removeDeliveredNotifications(withIdentifiers: removeEMA)
                HomeVC.currentEMAIdents.remove(at: 0)
            }else{
                HomeVC.emaActive = false
                if HomeVC.suddenEMA.count > 0{
                    //HomeVC.deliveryTime = Int64(Date().timeIntervalSince1970 * 1000)
                    switch HomeVC.suddenEMA[0] {
                    case "RiskEMANotification":
                        let ident = HomeVC.suddenEMAIdents.remove(at: 0)
                        AppDelegate.study?.startRiskEMA(ident: ident)
                        //self.startRiskEMASurvey(identifier: ident)
                    case "DailyEMANotification":
                        let ident = HomeVC.suddenEMAIdents.remove(at: 0)
                        AppDelegate.study?.startDailyEMA(ident: ident)
                        //self.startDailyEMASurvey(identifier: ident)
                    case "ScheduledEMANotification":
                        let ident = HomeVC.suddenEMAIdents.remove(at: 0)
                        AppDelegate.study?.startIntensiveEMA(ident: ident)
                        //self.startSurvey(identifier: ident)
                    default:
                        HomeVC.suddenEMAIdents.remove(at: 0)
                        NSLog("error: unexpected EMA Notification identifier in EMA chain.")
                    }
                    HomeVC.suddenEMA.remove(at: 0)
                }else{
                    if HomeVC.missedIntensive{
                        // TODO: Implement missing balloon.
                        AppDelegate.study?.startIntensiveEMA(ident: "")
                        //self.startSurvey(identifier: "")
                        //HomeVC.missedIntensive = false
                        return
                    }
                    if HomeVC.missedDaily{
                        AppDelegate.study?.startDailyEMA(ident: "")
                        //self.startDailyEMASurvey(identifier: "")
                        //HomeVC.missedDaily = false
                        return
                    }
                    if HomeVC.missedRisk{
                        AppDelegate.study?.startRiskEMA(ident: "")
                        //self.startRiskEMASurvey(identifier: "")
                        //HomeVC.missedRisk = false
                        return
                    }
                }
                
            }
            
        }
        

    }
    
    func getNotificaitonList() -> [String]{
        let center = UNUserNotificationCenter.current()
        
        var identList:[String] = []
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            for notification in notifications {
                identList.append(notification.request.identifier)
            }
        })
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                identList.append(request.identifier)
            }
        })
        return identList
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    func getSpecificNotificationInterval(beginInterval: Date) -> TimeInterval{
        
        
        let currentDateTime = beginInterval
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        //print(dateString)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let midnight:String
        if isScheduleOdd(){
            midnight = dateString + "22:59:59" + timeZoneString //1 second before Midnight
        }else{
            midnight = dateString + "23:59:59" + timeZoneString //1 second before Midnight
        }
        let midnightTarget = dateFormatter.date(from: midnight)
        var range: Double = 0
        var resultInterval:TimeInterval = 0
        //let inter = midnightTarget!.timeIntervalSinceNow / (60 * 60)
        let inter = midnightTarget!.timeIntervalSince(beginInterval) / (60 * 60)
        range = inter.truncatingRemainder(dividingBy: 2) * (60 * 60 )
        //print(range)
        if range - 1800 <= 0{
            //do it now, this probably shouldn't happen
            //print("send now")
            resultInterval = TimeInterval(1)
        }else{
            resultInterval = TimeInterval(arc4random_uniform(UInt32(range) - 3600) + 1800)
            //print("resultInterval: \(resultInterval)")
        }
        //print("Current EMA Notification will appear in \((resultInterval + beginInterval.timeIntervalSinceNow) / 60) minutes.")
        
        var nowInterval = resultInterval + beginInterval.timeIntervalSinceNow
        if nowInterval < 0{
            nowInterval = 60
        }
        return nowInterval
    }
    // MARK: roundUpHour()
    func roundUpHour()-> Date{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: currentDateTime))! + timeZoneString
                
        let startTarget = dateFormatter.date(from: dailyStart)
        dateFormatter.dateFormat = "HH"
        let hourString = dateFormatter.string(from: startTarget!)
        
        //print("\(hourString)")
        
        
        if hourString.first == "0"{
            if Int(String(hourString.last!))! % 2 == 0{
                //print("even")
                return roundUpEvenHours()
            }else{
                //print("odd")
                return roundUpOddHours()
            }
        }else{
            if Int(String(hourString))! % 2 == 0{
                //print("even")
                return roundUpEvenHours()
            }else{
                //print("odd")
                return roundUpOddHours()
            }
        }

    }
    
    func roundUpEvenHours()-> Date{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        
        dateFormatter.dateFormat = "HH"
        
        let hourString = dateFormatter.string(from: currentDateTime)

        if hourString.first == "0"{
            if Int(String(hourString.last!))! % 2 == 0{
                let newDate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }else{
                let newDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }
        }else{
            
            if Int(String(hourString))! % 2 == 0{
                let newDate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }else{
                let newDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }
        }
    }
    
    func roundUpOddHours()-> Date{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        
        dateFormatter.dateFormat = "HH"
        
        let hourString = dateFormatter.string(from: currentDateTime)
        
        //TODO: what about midnight?
        if hourString.first == "0"{
            if Int(String(hourString.last!))! % 2 != 0{
                let newDate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }else{
                let newDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }
        }else{
            
            if Int(String(hourString))! % 2 != 0{
                let newDate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }else{
                let newDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDateTime)!
                let newHourString = dateFormatter.string(from: newDate)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                let finalString = dateString + newHourString + ":00:00" + timeZoneString
                let final = dateFormatter.date(from:  finalString)
                return final!
            }
        }
    }
    
    func isScheduleOdd()-> Bool{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: currentDateTime))! + timeZoneString
                
        let startTarget = dateFormatter.date(from: dailyStart)
        dateFormatter.dateFormat = "HH"
        let hourString = dateFormatter.string(from: startTarget!)
        
        //print("\(hourString)")
        
        
        if hourString.first == "0"{
            if Int(String(hourString.last!))! % 2 == 0{
                //print("even")
                return false
            }else{
                //print("odd")
                return true
            }
        }else{
            if Int(String(hourString))! % 2 == 0{
                //print("even")
                return false
            }else{
                //print("odd")
                return true
            }
        }

    }
        
        
    
    func getIntervalRangeDate(with date: Date)-> Date{
        
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: date))! + timeZoneString
        let dailyEnd = dateString + (AppDelegate.study?.getDailyEnd(for: date))! + timeZoneString
 
        let nextDate = Calendar.current.date(byAdding: .hour, value: 2, to: date)!
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        let nextDateDay = dateFormatter.string(from: nextDate)
        let dateDay = dateFormatter.string(from: date)
        
        if dateDay != nextDateDay{
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            let newDate = nextDateDay + (AppDelegate.study?.getDailyStart(for: nextDate))! + timeZoneString
            let newTarget = dateFormatter.date(from: newDate)
            //print("newTarget: \(newTarget!)")
            return newTarget!
        }
        return nextDate
        
    }
    
    // MARK: getNotificationInterval
    /// This function calculates and then returns an appropriate TimeInterval for when the next scheduled EMA should be presented. Scheduled times are calculated to randomly fall within the bounds of 2 hour time segments between a time frame (8AM and 12AM) with a 30 minute buffer from the beginning of the hour or beginning of app restart (assuming there are 30 minutes left in the hour.) If the app is restarted at 1:40PM and a previous EMA notification had been delivered already within the current time segment (12:00PM to 2:00PM), it will schedule an EMA for the next time window (2:00PM to 4:00PM). If the app is restarted after 12AM but before 8AM it will not schedule again until the first time slot on the next day (8AM to 10AM.)
    ///
    /// - Returns: Seconds until the next EMA Notification will be scheduled.
    func getNotificationInterval() -> TimeInterval{
        
        
        let center = UNUserNotificationCenter.current()
        var pendingRemovalList:[String] = []
        var deliveredRemovalList:[String] = []
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                //print(request.content.categoryIdentifier)
                if request.content.categoryIdentifier == "ScheduledEMANotification"{
                    pendingRemovalList.append(request.identifier)
                    //print(request.identifier)
                }
            }
            center.removePendingNotificationRequests(withIdentifiers: pendingRemovalList)
        })
        center.getDeliveredNotifications(completionHandler: { notifications in
            for notification in notifications {
                //print(notification.request.content.categoryIdentifier)
                if notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
                    deliveredRemovalList.append(notification.request.identifier)
                    //print(notification.request.identifier)
                }
            }
            center.removeDeliveredNotifications(withIdentifiers: deliveredRemovalList)
        })
 
        
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let midnight = dateString + "23:59:59" + timeZoneString //1 second before Midnight
        let midnightTarget = dateFormatter.date(from: midnight)
        
        var range: Double = 0
        var resultInterval:TimeInterval = 0
        let inter = midnightTarget!.timeIntervalSinceNow / (60 * 60)
        range = inter.truncatingRemainder(dividingBy: 2) * (60 * 60 )
        //print(range)
        if range - 1800 <= 0{
            resultInterval = TimeInterval(arc4random_uniform(UInt32(range)))
        }else{
            resultInterval = TimeInterval(arc4random_uniform(UInt32(range) - 1800) + 1800)
        }
        //print("Current EMA Notification will appear in \(resultInterval / 60) minutes.")
        //print("Next EMA time window will be in \((range / 60)) minutes.")
        
        //print("\(BatteryManager.batteryLevel ?? -1)")
        return resultInterval
    }
    func checkEMAWindowForDatetime(date: Date) -> Bool{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: date))! + timeZoneString
        let dailyEnd = dateString + (AppDelegate.study?.getDailyEnd(for: date))! + timeZoneString
        //print("\((AppDelegate.study?.getDailyEnd(for: date))!)")
        let startTarget = dateFormatter.date(from: dailyStart)
        let endTarget = dateFormatter.date(from: dailyEnd)
        
        if (currentDateTime >= startTarget!) && (currentDateTime < endTarget!){
            return true
        }
        
        return false
    }
    
    func checkIfBeforeDailyStart(date: Date) -> Bool{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + (AppDelegate.study?.getDailyStart(for: date))! + timeZoneString
        let startTarget = dateFormatter.date(from: dailyStart)
        
        if (currentDateTime <= startTarget!){
            return true
        }
        
        return false
    }
    
    /// This function returns a bool indicating if the current time falls within the bounds of the EMA start and end parameters in the StudyManager class.
    ///
    /// - Returns: true if ema is okay to schedule.
    func checkEMAWindow() -> Bool{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + (AppDelegate.study?.emaDailyStart)! + timeZoneString
        let dailyEnd = dateString + (AppDelegate.study?.emaDailyEnd)! + timeZoneString //1 second before Midnight
        let startTarget = dateFormatter.date(from: dailyStart)
        let endTarget = dateFormatter.date(from: dailyEnd)

        if (currentDateTime >= startTarget!) && (currentDateTime <= endTarget!){
            return true
        }
        
        return false
    }
    
    func checkDailyEMAWindowForDatetime(date: Date) -> Bool{
        let currentDateTime = date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart: String
        if (AppDelegate.study?.customDailyEMADeliveryTime.count)! > 0{
            //print("customDailyTime")
            dailyStart = dateString + AppDelegate.study!.customDailyEMADeliveryTime + timeZoneString
            //print("\(dailyStart)")
        }else{
            dailyStart = dateString + "08:00:00" + timeZoneString
        }
        let dailyEnd = dateString + "23:59:59" + timeZoneString
        let startTarget = dateFormatter.date(from: dailyStart)
        let endTarget = dateFormatter.date(from: dailyEnd)
        
        if (currentDateTime >= startTarget!) && (currentDateTime <= endTarget!){
            return true
        }
        
        return false
    }
    
    /// This function returns a bool indicating if the current time is greater than the daily EMA start time (default 8:00am)
    ///
    /// - Returns: true if time is after 8:00am
    func checkDailyEMAStart() -> Bool{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart: String
        if (AppDelegate.study?.customDailyEMADeliveryTime.count)! > 0{
            dailyStart = dateString + AppDelegate.study!.customDailyEMADeliveryTime + timeZoneString
        }else{
            dailyStart = dateString + "08:00:00" + timeZoneString
        }
        let startTarget = dateFormatter.date(from: dailyStart)

        if (currentDateTime >= startTarget!){
            return true
        }
        
        return false
    }
    
    /// This function will return a bool if the current time between 9am and 5pm.
    ///
    /// - Returns: bool if EMA should be presented.
    func checkRiskEMAStart() -> Bool{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + "09:00:00" + timeZoneString
        let dailyEnd   = dateString + "17:00:00" + timeZoneString
        let startTarget = dateFormatter.date(from: dailyStart)
        let endTarget   = dateFormatter.date(from: dailyEnd)
        
        if (currentDateTime >= startTarget!) && (currentDateTime <= endTarget!){
            return true
        }
        
        return false
    }
    
    func checkGivenRiskEMAStart(given: Date) -> Bool{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        let dateString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let dailyStart = dateString + "08:59:00" + timeZoneString
        let dailyEnd   = dateString + "17:00:00" + timeZoneString
        let startTarget = dateFormatter.date(from: dailyStart)
        let endTarget   = dateFormatter.date(from: dailyEnd)
        
        if (given >= startTarget!) && (given <= endTarget!){
            return true
        }
        
        return false
    }
    
    
    /// This function records the current battery state to a fille and should be called when battery state listener is invoked.
    @objc func localBatteryStateDidChange(){
        let queue = DispatchQueue(label: "SerialQueueBattery")
        
        //Pull the latest data
        queue.async {
            self.bat!.batteryStateDidChange()
        }
        
    }
    @objc func localBatteryChargeDidChange(){
        bat!.batteryStateDidChange()
    
    }
    
    /// a listener function to be added to a MPMusicPlayerControllerNowPlayingItemDidChange observer that records Apple Music songs listened to on the device.
    @objc func getNowPlayingItem() {
        
        if let mediaItem = MusicManager.player.nowPlayingItem {

            if MusicManager.player.playbackState == MPMusicPlaybackState.playing {
                //let title: String = "\(mediaItem.value(forProperty: MPMediaItemPropertyTitle) ?? "Unknown")"
                //let artist: String = "\(mediaItem.value(forProperty: MPMediaItemPropertyArtist) ?? "Unknown")"

                let musicProtobuf = Research_MusicEvent.with {
                    $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                    $0.app = "com.apple.Music"
                    $0.title = "\(mediaItem.value(forProperty: MPMediaItemPropertyTitle) ?? "Unknown")"
                    $0.text = "\(mediaItem.value(forProperty: MPMediaItemPropertyArtist) ?? "Unknown")"
                }
                
                AppDelegate.mus.recordMusic(songInfo: musicProtobuf)
                
            }
        }
        
    }
 
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        
    }
    
    /// Checks if permissions are currently enabled for vital sensors. If not, present a UIAlertController informing users this is occuring.
    func checkVitalPermissions(){
        
        if(CMMotionActivityManager.authorizationStatus() != .authorized && (AppDelegate.study?.includedSensors["accel"])! && CMMotionActivityManager.isActivityAvailable()){
            DispatchQueue.main.async {
            let alert = UIAlertController()
                alert.createSettingsAlertController(fromController: self,title: "motionAlertTitle".localized(), message: "motionAlertMessage".localized())
            }
        }
        
        //Notify user they have turned off location services if it's included in their study
        if(!AppDelegate.gps.locationEnabled() && (AppDelegate.study?.includedSensors["gps"])!){
            DispatchQueue.main.async {
            let alert = UIAlertController()
                alert.createSettingsAlertController(fromController: self,title: "locAlertTitle".localized(), message: "locAlertMessage".localized())
            }
            
        }
        //Notify user they have turned off music services if it's included in their study
        if(MPMediaLibrary.authorizationStatus() != MPMediaLibraryAuthorizationStatus.authorized && (AppDelegate.study?.includedSensors["music"])! && AppDelegate.study?.study.lowercased() != "REDACTED"){
             /* REDACTED */
        }
        if #available(iOS 10.0, *) {
            let current = UNUserNotificationCenter.current()
            current.getNotificationSettings(completionHandler: { settings in
                
                if settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .denied{
                    DispatchQueue.main.async {
                        let alert = UIAlertController()
                        alert.createSettingsAlertController(fromController: self,title: "notifAlertTitle".localized(), message: "notifAlertMessage".localized())
                    }
                }else{
                    AppDelegate.pushCheckEnabled = true
                }
            })
        } else {
            // Fallback on earlier versions
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                //print("APNS-YES")
            } else {
                //print("APNS-NO")
                DispatchQueue.main.async {
                    let alert = UIAlertController()
                    alert.createSettingsAlertController(fromController: self,title: "notifAlertTitle".localized(), message: "notifAlertMessage".localized())
                }
            }
        }
        
    }
    // MARK: viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.gradientSetup()
        self.checkVitalPermissions()

        if Date(timeIntervalSince1970: Double(AppDelegate.lastUploadTime / 1000)) < Calendar.current.date(byAdding: .hour, value: -1, to: Date())!{
            AppDelegate.updateOnPush() { (success) -> Void in
                let queue = DispatchQueue(label: "home_viewDidAppear")
                queue.asyncAfter(deadline: .now() + TimeInterval(5), execute:{
                    AppDelegate.uploadInProgress = false
                })
                
                self.batchScheduleEMADaily() { (success) -> Void in
                    //Check if Risk EMAs need to be scheduled.
                    if (AppDelegate.study?.includedSensors["risk_ema"])!{
                        self.batchScheduleEMARisk() { (success) -> Void in
                            self.batchScheduleEMA() { (success) -> Void in
                                queue.asyncAfter(deadline: .now() + TimeInterval(1.5), execute:{
                                    //Possible Thread Conflict Here
                                    EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
                                })
                                //print("batchScheduleEMA complete: \(AppDelegate.lastScheduledEMADatetime)")
                                if (PHPhotoLibrary.authorizationStatus() == .authorized) {
                                    let group = DispatchGroup()
                                    let dispatch = DispatchQueue(label: "selfieCropAppear")
                                    dispatch.async{
                                        var continueCollecting = true
                                        while continueCollecting {
                                            let selfieCollect = SelfieCollectionManager()
                                            group.enter()
                                            selfieCollect.collect() { (success) -> Void in
                                                continueCollecting = success
                                                group.leave()
                                            }
                                            group.wait()
                                            if AppDelegate.memoryWarning{
                                                AppDelegate.memoryWarning = false
                                                continueCollecting = false
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                        self.batchScheduleEMA() { (success) -> Void in
                            EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
                            //print("batchScheduleEMA complete: \(AppDelegate.lastScheduledEMADatetime)")
                            if (PHPhotoLibrary.authorizationStatus() == .authorized) {
                                let group = DispatchGroup()
                                let dispatch = DispatchQueue(label: "selfieCropAppear")
                                dispatch.async{
                                    var continueCollecting = true
                                    while continueCollecting {
                                        let selfieCollect = SelfieCollectionManager()
                                        group.enter()
                                        selfieCollect.collect() { (success) -> Void in
                                            continueCollecting = success
                                            group.leave()
                                        }
                                        group.wait()
                                        if AppDelegate.memoryWarning{
                                            AppDelegate.memoryWarning = false
                                            continueCollecting = false
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }else{
            //NSLog("no upload required, last upload:\(AppDelegate.homeInstance.printTimezoneDate(date: Date(timeIntervalSince1970: Double(AppDelegate.lastUploadTime / 1000))))")
                self.batchScheduleEMADaily() { (success) -> Void in
                    //Check if Risk EMAs need to be scheduled.
                    if (AppDelegate.study?.includedSensors["risk_ema"])!{
                        self.batchScheduleEMARisk() { (success) -> Void in
                            self.batchScheduleEMA() { (success) -> Void in
                                let queue = DispatchQueue(label: "home_viewDidAppear_else")
                                queue.asyncAfter(deadline: .now() + TimeInterval(1.5), execute:{
                                    //Possible Thread Conflict Here
                                    EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
                                })
                                //print("batchScheduleEMA complete: \(AppDelegate.lastScheduledEMADatetime)")
                                if (PHPhotoLibrary.authorizationStatus() == .authorized) {
                                    let group = DispatchGroup()
                                    let dispatch = DispatchQueue(label: "selfieCropAppear")
                                    dispatch.async{
                                        var continueCollecting = true
                                        while continueCollecting {
                                            let selfieCollect = SelfieCollectionManager()
                                            group.enter()
                                            selfieCollect.collect() { (success) -> Void in
                                                continueCollecting = success
                                                group.leave()
                                            }
                                            group.wait()
                                            if AppDelegate.memoryWarning{
                                                AppDelegate.memoryWarning = false
                                                continueCollecting = false
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                        self.batchScheduleEMA() { (success) -> Void in
                            EarsService.shared.setEMALog(newValue: AppDelegate.emaLog)
                            //print("batchScheduleEMA complete: \(AppDelegate.lastScheduledEMADatetime)")
                            if (PHPhotoLibrary.authorizationStatus() == .authorized) {
                                let group = DispatchGroup()
                                let dispatch = DispatchQueue(label: "selfieCropAppear")
                                dispatch.async{
                                    var continueCollecting = true
                                    while continueCollecting {
                                        let selfieCollect = SelfieCollectionManager()
                                        group.enter()
                                        selfieCollect.collect() { (success) -> Void in
                                            continueCollecting = success
                                            group.leave()
                                        }
                                        group.wait()
                                        if AppDelegate.memoryWarning{
                                            AppDelegate.memoryWarning = false
                                            continueCollecting = false
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            
        }
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        AppDelegate.memoryWarning = true
        //NSLog("EARS memory warning!")
        //AppDelegate.selfieCollect = SelfieCollectionManager()
        
    }
    
    /// Function that sets a 'fun' shifting gradient background. If reduce motion is enabled, it will simply draw a gradient.
    private func gradientSetup() {
        gradientSet.append([gradientThree, gradientTwo])
        gradientSet.append([gradientOne, gradientTwo])
        gradientSet.append([gradientTwo, gradientOne])
        gradientSet.append([gradientTwo, gradientThree])
        
        
        gradient.frame = gradientView.bounds
        gradient.startPoint = CGPoint(x:0, y:0)
        gradient.endPoint = CGPoint(x:1, y:1)
        gradient.drawsAsynchronously = true
        
        if !UIAccessibility.isReduceMotionEnabled {
            gradient.colors = gradientSet[currentGradient]
            self.gradientView.layer.addSublayer(gradient)
            animateGradient()
        }else{
            gradient.colors = gradientSet[1]
            self.gradientView.layer.addSublayer(gradient)
        }
    }
    
    private func animateGradient() {
        if currentGradient < gradientSet.count - 1 {
            currentGradient += 1
        } else {
            currentGradient = 0
        }
        
        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.duration = 15.0
        gradientChangeAnimation.autoreverses = true
        gradientChangeAnimation.repeatCount = Float.infinity
        gradientChangeAnimation.toValue = gradientSet[currentGradient]
        gradientChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradient.add(gradientChangeAnimation, forKey: "colorChange")
    }
    
    
    /// If UIImages in HomeVC are nil, load images.
    func loadImages(){
        //if earsImage.image == nil{
        earsImage.tintColor = nil
        earsImage.image = UIImage(named: "bunnySplash1")
        titleLabel.text = "homeTitle".localized()
        //}
        if earsIcon.image == nil{
            earsIcon.image = UIImage(named: "earsIcon")
        }
    }
    
    /// Set HomeVC images to nil to reduce memory when in background.
    func unloadImages(){
        earsImage.image = nil
        earsIcon.image  = nil

    }
    func setStopImage(){
        earsImage.tintColor = #colorLiteral(red: 0.9568627451, green: 0.9215686275, blue: 0.2901960784, alpha: 1)
        if #available(iOS 13.0, *) {
            earsImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
        } else {
            // Fallback on earlier versions
            earsImage.image = UIImage(named: "exclamation")!.withRenderingMode(.alwaysTemplate)

        }
        titleLabel.text = "swipeWarning".localized()
        
        earsIcon.image  = nil
    }
    
    // MARK: viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    // MARK: viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    func getDuration(result: ORKResult) -> Float?{
        guard let startDate = result.startDate as Date?,
            let endDate = result.endDate as Date?
            else {return nil}
        let durationFormatter = NumberFormatter()
        durationFormatter.maximumFractionDigits = 2
        let duration = endDate.timeIntervalSince(startDate)
        
        return Float(duration)
    }
    
    let identifierIndexMap:[String:Int32] = ["test":0]
    // MARK: taskViewController
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        let currentDateTime = Int64(Date().timeIntervalSince1970 * 1000)
        var notificationUUID: String?
        var localAlertRequired = false
        var riskAnswers: [String:Any] = [:]
        var questionList:[Research_EMAEvent.Question] = []
        var isDaily = false
        var isRisk = false
        
        //Check if the first step contains the notification UUID
        if let instructionStep = taskViewController.task?.step?(withIdentifier:ORKInstruction0StepIdentifier){
            let step = instructionStep as! ORKInstructionStep

            if step.footnote != nil && step.footnote != ""{
                notificationUUID = step.footnote!
                currentEMAIdent = ""
            }else{
                //If there isn't a UUID,
                notificationUUID = "notDelivered"
            }
        }
        let gameInfo = reason == .completed ? increaseEMAScore(willIncrease: true) : increaseEMAScore(willIncrease: false)

        
        if reason == .completed {
            
            AppDelegate.lastCompletedEMADatetime = currentDateTime
            EarsService.shared.setLastCompletedEMADatetime(newValue: currentDateTime)
            
            if let dailyResult = taskViewController.result.stepResult(forStepIdentifier: "daily"){
                //print("\(dailyResult.results)")
                let dailyTimeResult = taskViewController.result.result(forIdentifier: "daily")
                HomeVC.missedDaily = false
                isDaily = true
                var answer: Int
                
                if dailyResult.firstResult?.value(forKey: "answer") != nil{
                    answer = dailyResult.firstResult?.value(forKey: "answer") as! Int
                }else{
                    answer = -1
                }
                let dailyEMAQuestion = Research_EMAEvent.Question.with {
                    $0.questionID = "daily"
                    $0.intAnswer = Int32(answer)
                    $0.completionTime = getDuration(result: dailyTimeResult!) ?? -1
                }
                
                questionList.append(dailyEMAQuestion)
                
                
                //answerDict[dailyResult.identifier] = answer
            }else if var riskOneResult = taskViewController.result.stepResult(forStepIdentifier: "riskOne")?.results{
                isRisk = true
                HomeVC.missedRisk = false

                //TODO determine risk question protobuf
                var riskTwoResult = taskViewController.result.stepResult(forStepIdentifier: "riskTwo")?.results
                var riskThreeResult = taskViewController.result.stepResult(forStepIdentifier: "riskThree")?.results
                
               
                let tempResultOne: ORKResult = (riskOneResult.removeFirst())
                let questionOne = tempResultOne as! ORKQuestionResult
                let answerOne = convertQuestionToAnswerString(question: questionOne)
                riskAnswers["\(tempResultOne.value(forKey: "identifier") ?? "nil" )"] = "\(answerOne)"
                let riskEMAQuestion1 = Research_EMAEvent.Question.with {
                    //$0.index = identifierIndexMap[tempResultOne.identifier]!
                    //$0.score = Int32(answerOne)
                    $0.questionID = "riskOne"
                    $0.stringAnswer = "\(answerOne)"
                    $0.completionTime = getDuration(result: tempResultOne) ?? -1
                }
                questionList.append(riskEMAQuestion1)
                
                
                let tempResultTwo: ORKResult = (riskTwoResult!.removeFirst())
                let questionTwo = tempResultTwo as! ORKQuestionResult
                let answerTwo = convertQuestionToAnswerString(question: questionTwo)
                riskAnswers["\(tempResultTwo.value(forKey: "identifier") ?? "nil" )"] = "\(answerTwo)"
                let riskEMAQuestion2 = Research_EMAEvent.Question.with {
                    $0.questionID = "riskTwo"
                    $0.boolAnswer = {
                        switch "\(answerTwo)" {
                        case "noVal".localized():
                            return .no
                        case "yesVal".localized():
                            return .yes
                        default:
                            return .unknown
                        }
                    }()
                    $0.completionTime = getDuration(result: tempResultTwo) ?? -1
                }
                //print("\(riskEMAQuestion2)")
                questionList.append(riskEMAQuestion2)

                
                let tempResultThree: ORKResult = (riskThreeResult!.removeFirst())
                let questionThree = tempResultThree as! ORKQuestionResult
                let answerThree = convertQuestionToAnswerString(question: questionThree)
                riskAnswers["\(tempResultThree.value(forKey: "identifier") ?? "nil" )"] = "\(answerThree)"
                let riskEMAQuestion3 = Research_EMAEvent.Question.with {
                    
                    $0.questionID = "riskThree"
                    $0.boolAnswer = {
                        switch "\(answerThree)" {
                        case "noVal".localized():
                            return .no
                        case "yesVal".localized():
                            return .yes
                        default:
                            return .unknown
                        }
                    }()
                    $0.completionTime = getDuration(result: tempResultThree) ?? -1
                }
                questionList.append(riskEMAQuestion3)

                
            }else{
                for each in (AppDelegate.study?.emaMoodIdentifiers)!{
                    let stepResult = taskViewController.result.stepResult(forStepIdentifier: each)
                    let timeResult = taskViewController.result.result(forIdentifier: each)
                    HomeVC.missedIntensive = false

                    var answer: Int
                    
                    if stepResult?.firstResult?.value(forKey: "answer") != nil{
                        answer = stepResult?.firstResult?.value(forKey: "answer") as! Int
                    }else{
                        answer = -1
                    }
                    
                    let emaQuestion = Research_EMAEvent.Question.with {
                        //$0.index = identifierIndexMap[stepResult?.identifier ?? "nil"]!
                        //$0.questionIdent = stepResult?.identifier ?? "nil"
                        $0.questionID = stepResult?.identifier ?? "nil"
                        $0.intAnswer = Int32(answer)
                        $0.completionTime = getDuration(result: timeResult!) ?? -1
                    }
                    
                    questionList.append(emaQuestion)
                    //print("\(stepResult!.results)")
                    
                }
                
            }
            

            
            // last question is always choiceAnswerFormat for Intensive EMA
            var stepResult = taskViewController.result.stepResult(forStepIdentifier: "recentContact")?.results
            
            //Check if stepResult exists (not included with dailyEMA riskEMA)
            if stepResult != nil{
                let tempResult: ORKResult = (stepResult?.removeFirst())!
                let question = tempResult as! ORKQuestionResult
                let answer = convertQuestionToAnswerString(question: question)
                //TODO implement question results for multiple choice
                let emaMultipleQuestion = Research_EMAEvent.Question.with {
                    //$0.index = identifierIndexMap[stepResult?.identifier ?? "nil"]!
                    //$0.questionIdent = stepResult?.identifier ?? "nil"
                    $0.questionID = "timeWith"
                    $0.stringAnswer = answer
                    $0.completionTime = getDuration(result: tempResult) ?? -1
                }
                questionList.append(emaMultipleQuestion)
                
                //answerDict["\(tempResult.value(forKey: "identifier") ?? "nil" )"] = "\(answer)"
            }

            
            // Results
            /*
            if let stepResult = taskViewController.result.stepResult(forStepIdentifier: QuestionStepIdentifier),
                let stepResults = stepResult.results,
                let stepFirstResult = stepResults.first,
                let booleanResult = stepFirstResult as? ORKBooleanQuestionResult,
                let booleanAnswer = booleanResult.booleanAnswer {
                //print("Result for question: \(booleanAnswer.boolValue)")
            }
            */
            
            
        }else{
 
            
            if let dailyResult = taskViewController.result.stepResult(forStepIdentifier: ORKInstruction0StepIdentifier + "Daily"){
                isDaily = true
            }else if var riskOneResult = taskViewController.result.stepResult(forStepIdentifier: ORKInstruction0StepIdentifier + "Risk")?.results{
                isRisk = true
            }
        }
        

        if isDaily{
            let dailyEMAProtoBuf = Research_EMAEvent.with {
                $0.timeInitiated = HomeVC.initiatedCurrentEMA
                $0.timeCompleted = currentDateTime
                $0.uuid = notificationUUID!
                $0.status = (reason == .completed) ? Research_EMAEvent.Status.complete : Research_EMAEvent.Status.cancelled
                $0.question = questionList
                if gameInfo != nil{
                    $0.gameLevel = Int32(gameInfo![0])
                    $0.gameStreak = Int32(gameInfo![1])
                    $0.gameLevelXp = gameInfo![2]
                }else{
                    $0.gameLevel = AppDelegate.emaRank
                    $0.gameStreak = Int32(getNumberOfDaysSinceEMAStreakStart())
                    $0.gameLevelXp = AppDelegate.emaXP
                }
            }
            AppDelegate.ema.recordDailyEMA(message: dailyEMAProtoBuf)
            
            let today = AppDelegate.getDay()
            AppDelegate.lastDailyEMARecieved = today
            EarsService.shared.setLastDailyEMARecieved(newValue: today)
        }
        if isRisk{
            var alertRequired = false
            var riskValues:[String] = []
            
            let riskEMAProtoBuf = Research_EMAEvent.with {
                $0.timeInitiated = HomeVC.initiatedCurrentEMA
                $0.timeCompleted = currentDateTime
                $0.uuid = notificationUUID!
                $0.status = (reason == .completed) ? Research_EMAEvent.Status.complete : Research_EMAEvent.Status.cancelled
                $0.question = questionList
                if gameInfo != nil{
                    $0.gameLevel = Int32(gameInfo![0])
                    $0.gameStreak = Int32(gameInfo![1])
                    $0.gameLevelXp = gameInfo![2]
                }else{
                    $0.gameLevel = AppDelegate.emaRank
                    $0.gameStreak = Int32(getNumberOfDaysSinceEMAStreakStart())
                    $0.gameLevelXp = AppDelegate.emaXP
                }
            }
            
            AppDelegate.ema.recordRiskEMA(message: riskEMAProtoBuf)
            
            let today = AppDelegate.getDay()
            AppDelegate.lastRiskEMARecieved = today
            EarsService.shared.setLastRiskEMARecieved(newValue: today)
            
            if let riskOne = riskAnswers["riskOne"]{
                riskValues.append(riskOne as! String)
            }
            if let riskTwo = riskAnswers["riskTwo"]{
                riskValues.append(riskTwo as! String)
            }
            if let riskThree = riskAnswers["riskThree"]{
                riskValues.append(riskThree as! String)
            }
            if riskValues.count > 0{
                //print("riskValues: \(riskValues)")
                for each in riskValues{
                    //print("each: \(each)")
                    switch each {
                        case "riskValueText3".localized():
                            localAlertRequired = true
                        case "yesVal".localized(),"riskValueText4".localized(),"riskValueText5".localized():
                            localAlertRequired = true
                            alertRequired = true
                            break
                        default:
                            continue
                    }
                }
                //print("alertRequired: \(alertRequired)")
                if alertRequired{
                    sendRiskAlert(deviceID: AppDelegate.device_id, study: (AppDelegate.study?.study)!, values: riskValues)
                }
            }
            
        }
        if !isRisk && !isDaily {
            let intensiveEMAProtoBuf = Research_EMAEvent.with {
                $0.timeInitiated = HomeVC.initiatedCurrentEMA
                $0.timeCompleted = currentDateTime
                $0.uuid = notificationUUID!
                $0.status = (reason == .completed) ? Research_EMAEvent.Status.complete : Research_EMAEvent.Status.cancelled
                $0.question = questionList
                if gameInfo != nil{
                    $0.gameLevel = Int32(gameInfo![0])
                    $0.gameStreak = Int32(gameInfo![1])
                    $0.gameLevelXp = gameInfo![2]
                }else{
                    $0.gameLevel = AppDelegate.emaRank
                    $0.gameStreak = Int32(getNumberOfDaysSinceEMAStreakStart())
                    $0.gameLevelXp = AppDelegate.emaXP
                }
            }
            HomeVC.missedIntensive = false
            AppDelegate.ema.recordEMA(message: intensiveEMAProtoBuf)
            let intensiveCompletedEpoch =  Int64(Date().timeIntervalSince1970 * 1000)
            AppDelegate.lastCompletedIntensiveEMADateTime = intensiveCompletedEpoch
            EarsService.shared.setLastCompletedIntensiveEMADateTime(newValue: intensiveCompletedEpoch)
        }
        dismiss(animated: true, completion: nil)
        
        if localAlertRequired{
            weak var vc = storyboard?.instantiateViewController(withIdentifier: "riskAlert") as? RiskAlertVC
            present(vc!,animated: true, completion: nil)
        }else{
            checkAvailableEMAs()
            //if notificationUUID != "notDelivered"{
            self.removedOldEMAs{ (success) -> Void in
                self.chainEMAs()
            }
            //}
        }
    }
    
    /// Converts the NSArray of an ORKQuestionResult into a stripped and readable String.
    ///
    /// - Parameter question: ORKQuestionResult you wish to format into a String
    /// - Returns: Stripped string answer to ORKQuestionResult.
    func convertQuestionToAnswerString(question: ORKQuestionResult) -> String{
        var answer = "\(question.answer ?? "(nil)")"
        answer = answer.replacingOccurrences(of: " ", with: "")
        answer = answer.replacingOccurrences(of: "\n", with: "")
        answer.removeFirst()
        answer.removeLast()
        
        return answer
    }
    
    
    let QuestionStepIdentifier = "step"
    
    static var emaActive = false
    /// Creates an ORKTaskViewController EMA Survey and presents it.
    func startSurvey(identifier: String?) {
        HomeVC.emaActive = true
        var identifiers:[String] = (AppDelegate.study?.emaMoodIdentifiers)!
        
        let answerFormatScale = ORKAnswerFormat.continuousScale(withMaximumValue: 100, minimumValue: 0, defaultValue: -1, maximumFractionDigits: 0, vertical: false, maximumValueDescription: "Extremely".localized(), minimumValueDescription: "Not at All".localized())
        let introStep = ORKInstructionStep(identifier: ORKInstruction0StepIdentifier)
        //introStep.title = NSLocalizedString("emaIntroTitle", comment: "")
        introStep.title = "emaIntroTitle".localized()
        //introStep.text  = NSLocalizedString("emaIntroText", comment: "")
        introStep.text  = "emaIntroText".localized()
        introStep.footnote = "\(identifier ?? "")"
        currentEMAIdent = "\(identifier ?? "")"
        
        
        let textChoice = [ORKTextChoice(text: "recentContactText0".localized(), value: "recentContactValue0".localized() as NSString),
                          ORKTextChoice(text: "recentContactText1".localized(), value: "recentContactValue1".localized() as NSString),
                          ORKTextChoice(text: "recentContactText2".localized(), value: "recentContactValue2".localized() as NSString),
                          ORKTextChoice(text: "recentContactText3".localized(), value: "recentContactValue3".localized() as NSString),
                          ORKTextChoice(text: "recentContactText4".localized(), value: "recentContactValue4".localized() as NSString),
                          ORKTextChoice(text: "recentContactText5".localized(), value: "recentContactValue5".localized() as NSString)]

        
        let choiceQuestion = ORKQuestionStep(identifier: "recentContact", title: "recentContactTitle".localized(), text: "recentContactQuestion".localized(), answer: ORKAnswerFormat.choiceAnswerFormat(with: ORKChoiceAnswerStyle.singleChoice, textChoices: textChoice))
        
        var shuffled:[ORKStep] = [introStep]
        
        for i in 0..<identifiers.count
        {
            
            let rand = Int(arc4random_uniform(UInt32(identifiers.count)))
            let step = ORKQuestionStep(identifier: identifiers[rand])
            step.title    = "\("Question".localized()) \(i+1)"
            step.text     = "\("How".localized()) \(identifiers[rand]) \("do you feel right now?".localized())"
            step.answerFormat = answerFormatScale
            shuffled.append(step)
            identifiers.remove(at: rand)
        }
        shuffled.append(choiceQuestion)
        
        //let completionStep = ORKOrderedTask.makeCompletionStep()
        
        //completionStep.text = NSLocalizedString("completionStepText", comment: "")
        //shuffled.append(completionStep)
        
        let task = ORKOrderedTask(identifier: "step", steps:shuffled)
        let viewController = ORKTaskViewController(task: task, taskRun: nil)
        
        viewController.delegate = self
        HomeVC.initiatedCurrentEMA = Int64(Date().timeIntervalSince1970 * 1000)
        if AppDelegate.homeInstance.sensorsVC != nil{
            AppDelegate.homeInstance.sensorsVC.dismiss(animated: false, completion: {
                self.present(viewController, animated:true, completion:nil)
            })
            AppDelegate.homeInstance.sensorsVC = nil
        }else if AppDelegate.homeInstance.popup != nil{
            AppDelegate.homeInstance.popup.dismiss(animated: false, completion: {
                self.present(viewController, animated:true, completion:nil)
            })
            AppDelegate.homeInstance.popup = nil
        }else{
            present(viewController, animated:true, completion:nil)
        }
    }
    
    /// Creates an ORKTaskViewController daily EMA Survey (one question) and presents it.
    func startDailyEMASurvey(identifier: String?) {
        HomeVC.emaActive = true
        let answerFormatScale = ORKAnswerFormat.continuousScale(withMaximumValue: 100, minimumValue: 0, defaultValue: -1, maximumFractionDigits: 0, vertical: false, maximumValueDescription: "Very Positive".localized(), minimumValueDescription: "Very Negative".localized())
        let introStep = ORKInstructionStep(identifier: ORKInstruction0StepIdentifier)
        introStep.title = "emaDailyIntroTitle".localized()
        introStep.text  = "emaIntroText".localized()
        introStep.footnote = "\(identifier ?? "")"
        currentEMAIdent = "\(identifier ?? "")"
        

        var stepList:[ORKStep] = [introStep]
        
        
        let step = ORKQuestionStep(identifier: "daily")
        step.title        = "Daily Question.".localized()
        if AppDelegate.studyName.lowercased() == "REDACTED"{
             /* REDACTED */
        }else{
            step.text         = "dailyQ".localized()
        }
        step.answerFormat = answerFormatScale
        stepList.append(step)
        
        //let completionStep = ORKOrderedTask.makeCompletionStep()
        
        //completionStep.text = NSLocalizedString("completionStepText", comment: "")
        //stepList.append(completionStep)
        
        let task = ORKOrderedTask(identifier: "step", steps:stepList)
        let viewController = ORKTaskViewController(task: task, taskRun: nil)
        
        viewController.delegate = self
        HomeVC.initiatedCurrentEMA = Int64(Date().timeIntervalSince1970 * 1000)
        if AppDelegate.homeInstance.sensorsVC != nil{
            AppDelegate.homeInstance.sensorsVC.dismiss(animated: false, completion: {
                self.present(viewController, animated:true, completion:nil)
            })
            AppDelegate.homeInstance.sensorsVC = nil
        }else if AppDelegate.homeInstance.popup != nil{
            AppDelegate.homeInstance.popup.dismiss(animated: false, completion: {
                self.present(viewController, animated:true, completion:nil)
            })
            AppDelegate.homeInstance.popup = nil
        }else{
            present(viewController, animated:true, completion:nil)
        }
    }
    
    /// Creates an ORKTaskViewController with risk EMA questions and presents it.
    func startRiskEMASurvey(identifier: String?) {
        HomeVC.emaActive = true
        let textChoiceOne = [ORKTextChoice(text: "riskAnswerText1".localized(), value: "riskValueText1".localized() as NSString),
                          ORKTextChoice(text: "riskAnswerText2".localized(), value: "riskValueText2".localized() as NSString),
                          ORKTextChoice(text: "riskAnswerText3".localized(), value: "riskValueText3".localized() as NSString),
                          ORKTextChoice(text: "riskAnswerText4".localized(), value: "riskValueText4".localized() as NSString),
                          ORKTextChoice(text: "riskAnswerText5".localized(), value: "riskValueText5".localized() as NSString)]
        
        let textChoiceBool = [ORKTextChoice(text: "yes".localized(), value: "yesVal".localized() as NSString),
                             ORKTextChoice(text: "no".localized(), value: "noVal".localized() as NSString)]
        
        //let choiceQuestionOne = ORKQuestionStep(identifier: "recentContact", title: NSLocalizedString("recentContactTitle", comment: ""), text: NSLocalizedString("recentContactQuestion", comment: ""), answer: ORKAnswerFormat.choiceAnswerFormat(with: ORKChoiceAnswerStyle.singleChoice, textChoices: textChoice))
        
        let introStep = ORKInstructionStep(identifier: ORKInstruction0StepIdentifier)
        introStep.title = "emaRiskIntroTitle".localized()
        introStep.text  = "emaIntroText".localized()
        introStep.footnote = "\(identifier ?? "")"
        currentEMAIdent = "\(identifier ?? "")"

        var stepList:[ORKStep] = [introStep]
        
        
        let stepOne = ORKQuestionStep(identifier: "riskOne")
        stepOne.title        = "Question 1".localized()
        stepOne.text         = "riskQ1".localized()
        stepOne.answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: ORKChoiceAnswerStyle.singleChoice, textChoices: textChoiceOne)
        stepList.append(stepOne)
        
        let stepTwo = ORKQuestionStep(identifier: "riskTwo")
        stepTwo.title        = "Question 2".localized()
        stepTwo.text         = "riskQ2".localized()
        stepTwo.answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: ORKChoiceAnswerStyle.singleChoice, textChoices: textChoiceBool)
        stepList.append(stepTwo)
        
        let stepThree = ORKQuestionStep(identifier: "riskThree")
        stepThree.title        = "Question 3".localized()
        stepThree.text         = "riskQ3".localized()
        stepThree.answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: ORKChoiceAnswerStyle.singleChoice, textChoices: textChoiceBool)
        stepList.append(stepThree)
        
        //let completionStep = ORKOrderedTask.makeCompletionStep()
        
        //completionStep.text = NSLocalizedString("completionStepText", comment: "")
        //stepList.append(completionStep)
        
        let task = ORKOrderedTask(identifier: "step", steps:stepList)
        let viewController = ORKTaskViewController(task: task, taskRun: nil)
        
        viewController.delegate = self
        HomeVC.initiatedCurrentEMA = Int64(Date().timeIntervalSince1970 * 1000)
        if AppDelegate.homeInstance.sensorsVC != nil{
            AppDelegate.homeInstance.sensorsVC.dismiss(animated: false, completion: {
                 self.present(viewController, animated:true, completion:nil)
            })
            AppDelegate.homeInstance.sensorsVC = nil
        }else if AppDelegate.homeInstance.popup != nil{
            AppDelegate.homeInstance.popup.dismiss(animated: false, completion: {
                self.present(viewController, animated:true, completion:nil)
            })
            AppDelegate.homeInstance.popup = nil
        }else{
            present(viewController, animated:true, completion:nil)
        }
    }
    func immediateDeactivation(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryStateDidChangeNotification, object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        //Check if Sensors view is open
        if AppDelegate.homeInstance.sensorsVC != nil{
            AppDelegate.homeInstance.sensorsVC.dismiss(animated: true, completion: nil)
            AppDelegate.homeInstance.sensorsVC = nil
        }
        if AppDelegate.homeInstance.popup != nil{
            AppDelegate.homeInstance.popup.dismiss(animated: false, completion: nil)
            AppDelegate.homeInstance.popup = nil
        }
        AppDelegate.homeInstance = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: {
            appDelegate.changeRootViewController(with: "deactivated")
        })
    }
    func presentInvalidEMADialog(){
        // Prepare the popup assets
        let title = "invalidEMATitle".localized()
        let message : String
        if AppDelegate.study?.customIntensiveExpiration != 0{
            message = "\("invalidEMADescriptionInterval".localized()) \(AppDelegate.study!.customIntensiveExpiration / 60) minutes."
        }else{
            message = "invalidEMADescription".localized()
        }
            //let image = UIImage(named: "pexels-photo-103290")

            // Create the dialog
            popup = PopupDialog(title: title, message: message)
            

            // Create buttons
        let buttonOne = CancelButton(title: "Okay".localized()) {
                //NSLog("Okay button clicked \(self.popup == nil)")
                self.popup = nil
            }

            // Add buttons to dialog
            // Alternatively, you can use popup.addButton(buttonOne)
            // to add a single button
            popup.addButtons([buttonOne])

            // Present dialog
            self.present(popup, animated: true, completion: nil)
        
    }
    
    private var notificationTimeFetchedResultsController: NSFetchedResultsController<SetupComplete>!
    
    // MARK: EMA Homescreen features
    func setExpandingTVC(view: ExpandingTVC){
        expandingTVC = view
    }
    static var missedIntensive = false
    static var missedDaily = false
    static var missedRisk = false
    
    func checkAvailableEMAs(){
        HomeVC.missedIntensive = false
        HomeVC.missedDaily = false
        HomeVC.missedRisk = false
        self.getPendingThisPhase{ (pendingRequests) -> Void in
            var count = 0
            let pendingCount = pendingRequests.count
            if pendingCount == 0{
                
                //print("\(Date(timeIntervalSince1970: TimeInterval(AppDelegate.lastCompletedIntensiveEMADateTime / 1000)))")
                
                if !self.checkValidEMA(for: Date(timeIntervalSince1970: TimeInterval(AppDelegate.lastCompletedIntensiveEMADateTime / 1000))) && self.checkEMAWindowForDatetime(date: Date()) && Date() >= AppDelegate.phaseStart! && Date() <= AppDelegate.phaseEnd!{
                    if (AppDelegate.study?.study != "REDACTED"{
                         /* REDACTED */
                        HomeVC.missedIntensive = true
                        count += 1
                    }
                    
                }
                if AppDelegate.lastDailyEMARecieved != AppDelegate.getDay() && self.checkDailyEMAStart(){
                    //custom expiration rules
                    if (AppDelegate.study?.study == "REDACTED"){
                         /* REDACTED */
                    }else{
                        //Add notification badge
                        HomeVC.missedDaily = true
                        count += 1
                    }
                }
                
                if AppDelegate.lastRiskEMARecieved != AppDelegate.getDay() && self.checkRiskEMAStart() && AppDelegate.itIsWednesday() && (AppDelegate.study?.includedSensors["risk_ema"])!{
                    //Add notification badge
                    HomeVC.missedRisk = true
                    //print("Risk")
                    count += 1
                }
                
                if self.expandingTVC != nil{
                    DispatchQueue.main.async{
                        self.expandingTVC.updateBadge(number: count)
                    }
                }else{
                    DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(1.5), execute:{
                        if self.expandingTVC != nil{
                            self.expandingTVC.updateBadge(number: count)
                        }else{
                            //NSLog("unable to locate expandingTVC delegate.")
                        }
                    })
                }
            }else{
                let identifierList = ["ScheduledEMANotification","DailyEMANotification", "RiskEMANotification"]
                let pendingIdentifiers = pendingRequests.map{$0.content.categoryIdentifier}
                let answer = identifierList.compactMap{!pendingIdentifiers.contains($0) ? $0 : nil}
                //print("\(answer)")
                for each in answer{
                    switch each {
                    case "ScheduledEMANotification":
                        if !self.checkValidEMA(for: Date(timeIntervalSince1970: TimeInterval(AppDelegate.lastCompletedIntensiveEMADateTime / 1000))) && self.checkEMAWindowForDatetime(date: Date()) && Date() >= AppDelegate.phaseStart! && Date() <= AppDelegate.phaseEnd!{                            //Add notification badge
                                if (AppDelegate.study?.study != "REDACTED"){
                                     /* REDACTED */
                                    HomeVC.missedIntensive = true
                                    count += 1
                                }
                        }
                    case "DailyEMANotification":
                        if AppDelegate.lastDailyEMARecieved != AppDelegate.getDay() && self.checkDailyEMAStart(){
                            //custom expiration rules
                            if (AppDelegate.study?.study == "REDACTED"){
                                /* REDACTED */
                            }else{
                                //Add notification badge
                                HomeVC.missedDaily = true
                                count += 1
                            }

                        }
                    case "RiskEMANotification":
                        if AppDelegate.lastRiskEMARecieved != AppDelegate.getDay() && self.checkRiskEMAStart() && AppDelegate.itIsWednesday() && (AppDelegate.study?.includedSensors["risk_ema"])!{
                            //Add notification badge
                            HomeVC.missedRisk = true
                            count += 1

                        }
                    default:
                        NSLog("error")
                    }
                }
                if self.expandingTVC != nil{
                    DispatchQueue.main.async{
                        self.expandingTVC.updateBadge(number: count)
                    }
                }else{
                    DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(1.5), execute:{
                        if self.expandingTVC != nil{
                            self.expandingTVC.updateBadge(number: count)
                        }else{
                            //NSLog("unable to locate expandingTVC delegate.")
                        }
                    })
                }

                
            }
            
        }
    }

    func getDeliveredThisPhase(completion: @escaping (_ success: [UNNotification]) -> Void){
        let center = UNUserNotificationCenter.current()
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{self.checkValidEMA(for: $0.date)}
            completion(scheduledNotifications)

        })
    }
    func removedOldEMAs(completion: @escaping (_ success: Bool) -> Void){
        self.removedOldIntensiveEMAs{ (success) -> Void in
            self.removedOldDailyEMAs{ (success) -> Void in
                self.removedOldRiskEMAs{ (success) -> Void in
                    DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(0.5), execute: {
                        completion(true)
                    })
                }
            }
        }

    }
    func removedOldIntensiveEMAs(completion: @escaping (_ success: Bool) -> Void){
        let center = UNUserNotificationCenter.current()
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "ScheduledEMANotification"}
            let invalidEMAs = scheduledNotifications.filter{!self.checkValidEMA(for: $0.date)}
            let removeList = invalidEMAs.map{$0.request.identifier}
            center.removeDeliveredNotifications(withIdentifiers: removeList)
            completion(true)
        })
    }
    func removedOldDailyEMAs(completion: @escaping (_ success: Bool) -> Void){
        let center = UNUserNotificationCenter.current()
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "DailyEMANotification"}
            let invalidEMAs = scheduledNotifications.filter{!self.checkValidDailyEMA(for: $0.date)}
            let removeList = invalidEMAs.map{$0.request.identifier}
            center.removeDeliveredNotifications(withIdentifiers: removeList)
            completion(true)
        })
    }
    func removedOldRiskEMAs(completion: @escaping (_ success: Bool) -> Void){
        let center = UNUserNotificationCenter.current()
        
        center.getDeliveredNotifications(completionHandler: { notifications in
            let scheduledNotifications = notifications.filter{$0.request.content.categoryIdentifier == "RiskEMANotification"}
            let invalidEMAs = scheduledNotifications.filter{!self.checkGivenRiskEMAStart(given: $0.date)}
            let removeList = invalidEMAs.map{$0.request.identifier}
            center.removeDeliveredNotifications(withIdentifiers: removeList)
            completion(true)

        })
    }
    func getPendingThisPhase(completion: @escaping (_ success: [UNNotificationRequest]) -> Void){
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests(completionHandler: { requests in
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
            formatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
            
            let scheduledNotifications = requests.filter{self.checkValidEMA(for: formatter.date(from: formatter.string(from: Date(timeIntervalSince1970: TimeInterval(Int64("\($0.content.userInfo["deliveryTime"]!)")! / 1000))))!)}
            completion(scheduledNotifications)
            
        })
    }

    
    
    // MARK: EMA Gamification code
    var popup: PopupDialog!
    @IBOutlet weak var rankBar: UIProgressView!
    @IBOutlet weak var rankNumberTitle: UILabel!
    @IBOutlet weak var numeratorLabel: UILabel!
    @IBOutlet weak var rankTitleLabel: UILabel!
    @IBOutlet weak var streakLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var rankDescription: UILabel!
    
    @IBOutlet weak var bunnyYAlign: NSLayoutConstraint!
    
    
    func hideGameVisuals(){
        bunnyYAlign.constant = 0
        rankBar.isHidden = true
        rankNumberTitle.isHidden = true
        numeratorLabel.isHidden = true
        rankTitleLabel.isHidden = true
        streakLabel.isHidden = true
        levelLabel.isHidden = true
        infoButton.isHidden = true
        rankDescription.isHidden = true
    }
    
    @IBAction func infoButton(_ sender: Any) {
        // Prepare the popup assets
        let title = "gameInfoTitle".localized()
        let message = "gameInfoDescription".localized()

        // Create the dialog
        popup = PopupDialog(title: title, message: message)
        
        // Create buttons
        let buttonOne = CancelButton(title: "Okay".localized()) {
            self.popup = nil
        }

        // Add buttons to dialog
        popup.addButtons([buttonOne])

        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func animateProgressBar(){
        // 1
        var oldProgress = (rankBar.progress * Float(self.getXPTotalForRank(newEMARank: Int(AppDelegate.emaRank))))
        //print("p: \(oldProgress)")

        // 2
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { (timer) in
            guard oldProgress < Float(AppDelegate.emaXP) else {
                timer.invalidate()
                return
            }
            
            // 3
            oldProgress += 1
            self.rankBar.setProgress(Float(oldProgress) / Float(self.getXPTotalForRank(newEMARank: Int(AppDelegate.emaRank))), animated: true)
            

        }
    }
    
    
    func updateEMAScore(){
        let missedEMADays = getNumberOfDaysSinceLastEMA()
        //print("missedEMADays: \(missedEMADays)")

        if missedEMADays <= 1{
            updateGameUI()
            return
        }else{
            AppDelegate.emaStreakStart = Int64(Date().timeIntervalSince1970 * 1000)
            EarsService.shared.setEMAStreakStart(newValue: AppDelegate.emaStreakStart)
        }
        if AppDelegate.gameEnabled{
            updateGameUI()
        }
        
        //print("EMA Rank: \(AppDelegate.emaRank)")
        //print("EMA XP for Rank: \(AppDelegate.emaXP)")
        
        AppDelegate.emaGameLastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        EarsService.shared.setEMAGameLastUpdated(newValue: AppDelegate.emaGameLastUpdated)
    }
    func getXPTotalForRank(newEMARank: Int) -> Int64{

        return Int64(getScoreForRankLevel(x: Double(newEMARank)))
    }
    
    func getNumberOfDaysSinceLastEMA() -> Int{
        //function returns a date for the day before at midnight
        //print("AppDelegate.lastCompletedEMADatetime: \(AppDelegate.lastCompletedEMADatetime)")
        if AppDelegate.lastCompletedEMADatetime == 0{
            AppDelegate.lastCompletedEMADatetime = Int64(Date().timeIntervalSince1970 * 1000)
        }
        var dateCheck = getDayBefore(date: Date())
        var numberOfDays = 0
        //check last EMA was greater than the day before, then the next etc
        while Date(timeIntervalSince1970: TimeInterval(AppDelegate.lastCompletedEMADatetime / 1000)) < dateCheck{
            numberOfDays += 1
            dateCheck = getDayBefore(date: dateCheck)
        }
        return numberOfDays
    }
    
    func getNumberOfDaysSinceEMAStreakStart() -> Int{
        //function returns a date for the day before at midnight
        if AppDelegate.emaStreakStart == 0{
            AppDelegate.emaStreakStart = Int64(Date().timeIntervalSince1970 * 1000)
            EarsService.shared.setEMAStreakStart(newValue: AppDelegate.emaStreakStart)
        }
        var dateCheck = getDayBefore(date: Date())
        var numberOfDays = 0
        //check last EMA was greater than the day before, then the next etc
        while Date(timeIntervalSince1970: TimeInterval(AppDelegate.emaStreakStart / 1000)) < dateCheck{
            numberOfDays += 1
            dateCheck = getDayBefore(date: dateCheck)
        }
        return numberOfDays
    }
    
    func getDayBefore(date: Date) -> Date{
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        let dateString = dateFormatter.string(from: yesterday!)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let dailyEnd = dateString + "23:59:59" //1 second before Midnight
        let endTarget = dateFormatter.date(from: dailyEnd)
        
        return endTarget!
    }
    
    func updateGameUI(){
        DispatchQueue.main.async {
            //print("\(AppDelegate.emaXP ) / \(self.getXPTotalForRank(newEMARank: Int(AppDelegate.emaRank))):\(Float(AppDelegate.emaXP) / Float(self.getXPTotalForRank(newEMARank: Int(AppDelegate.emaRank))))")
            self.rankNumberTitle.text = Int(AppDelegate.emaRank) < 10 ? "0\(AppDelegate.emaRank)" : "\(AppDelegate.emaRank)"
            self.numeratorLabel.text = "\(AppDelegate.emaXP) / \(self.getXPTotalForRank(newEMARank: Int(AppDelegate.emaRank)))"
            if self.emaRankChanged{
                self.rankBar.setProgress(0.0, animated: true)
                //self.rankTitleLabel.text = "rank\(AppDelegate.emaRank)".localized()
                self.emaRankChanged = false
            }
            if AppDelegate.emaRank < 30 {
                self.rankTitleLabel.text = "rank\(AppDelegate.emaRank)".localized()
            }else{
                self.rankTitleLabel.text = "rank30".localized()
            }
            if let streak = self.getNumberOfDaysSinceEMAStreakStart() as? Int, streak > 0 {
                //print("streak: \(streak)")
                self.streakLabel.text = "\(self.getNumberOfDaysSinceEMAStreakStart()) 🔥"
                if AppDelegate.gameEnabled{
                    self.streakLabel.isHidden = false
                }
            }else{
                self.streakLabel.isHidden = true
            }
            self.animateProgressBar()
        }
    }
    func getScoreForRankLevel(x: Double) -> Double{
        //return ((Double(100.0 * (x * 25.0))).squareRoot() + 50.0) / 100.0
        if x == 1.0{
            return 100
        }
        //https://www.wolframalpha.com/input/?i=y+%3D+%28sqrt%28100%28x%2B25%29%29%2B50%29%2F100
        return (((10 * x - 5) * (10 * x - 5)) - 25) - (((10 * (x - 1) - 5) * (10 * (x - 1) - 5)) - 25)
    }
    
    var emaRankChanged = false
    func increaseEMAScore(willIncrease: Bool) -> [Int64]?{
        if willIncrease == false{
            return nil
        }
        var resultXP: Int64 = 0;
        var resultRank: Int64 = 0;
        var resultStreak = 0;
        
        let baseXP = 100
        var streakBonus = 0
        let missedEMADays = getNumberOfDaysSinceLastEMA()
        if missedEMADays <= 1{
            resultStreak = getNumberOfDaysSinceEMAStreakStart()
            streakBonus = resultStreak * 20
        }
        let newScore = AppDelegate.emaXP + Int64(baseXP + streakBonus)
        let totalXPForRank = getXPTotalForRank(newEMARank: Int(AppDelegate.emaRank))
        
        if  totalXPForRank <= newScore{
            EarsService.shared.setEMARank(newValue: AppDelegate.emaRank + 1)
            AppDelegate.emaRank += 1
            resultRank = Int64(AppDelegate.emaRank)
            emaRankChanged = true
            let tempScore = newScore - totalXPForRank
            resultXP = tempScore
            AppDelegate.emaXP = tempScore
            EarsService.shared.setEMAXP(newValue: tempScore)
        }else{
            resultXP = newScore
            resultRank = Int64(AppDelegate.emaRank)
            AppDelegate.emaXP = newScore
            EarsService.shared.setEMAXP(newValue: newScore)
        }
        updateGameUI()
        return [resultRank, Int64(resultStreak), resultXP]
    }

}

extension HomeVC: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            gradient.colors = gradientSet[currentGradient]
            animateGradient()
        }
    }
}
extension UIAlertController {
    
    func createSettingsAlertController(fromController controller: UIViewController, title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings".localized(), style: .default) { (UIAlertAction) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)! as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        controller.present(alertController, animated: true, completion: nil)
        
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

extension Date {

  static func today() -> Date {
      return Date()
  }

  func next(_ weekday: Weekday, considerToday: Bool = false) -> Date {
    return get(.next,
               weekday,
               considerToday: considerToday)
  }

  func previous(_ weekday: Weekday, considerToday: Bool = false) -> Date {
    return get(.previous,
               weekday,
               considerToday: considerToday)
  }

  func get(_ direction: SearchDirection,
           _ weekDay: Weekday,
           considerToday consider: Bool = false) -> Date {

    let dayName = weekDay.rawValue

    let weekdaysName = getWeekDaysInEnglish().map { $0.lowercased() }

    assert(weekdaysName.contains(dayName), "weekday symbol should be in form \(weekdaysName)")

    let searchWeekdayIndex = weekdaysName.firstIndex(of: dayName)! + 1

    let calendar = Calendar(identifier: .gregorian)

    if consider && calendar.component(.weekday, from: self) == searchWeekdayIndex {
      return self
    }

    var nextDateComponent = calendar.dateComponents([.hour, .minute, .second], from: self)
    nextDateComponent.weekday = searchWeekdayIndex

    let date = calendar.nextDate(after: self,
                                 matching: nextDateComponent,
                                 matchingPolicy: .nextTime,
                                 direction: direction.calendarSearchDirection)

    return date!
  }

}

// MARK: Helper methods
extension Date {
  func getWeekDaysInEnglish() -> [String] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    return calendar.weekdaySymbols
  }

  enum Weekday: String {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
  }

  enum SearchDirection {
    case next
    case previous

    var calendarSearchDirection: Calendar.SearchDirection {
      switch self {
      case .next:
        return .forward
      case .previous:
        return .backward
      }
    }
  }
}

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
