import UIKit
import CoreData
import CoreMotion
import AWSCore
import AWSS3
import AWSCognito
import AWSMobileClient
import CallKit
import UserNotifications
import MediaPlayer
import UserNotificationsUI
import Firebase
import Photos
import BackgroundTasks


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NSFetchedResultsControllerDelegate {
    
    var callObserver: CXCallObserver!
    var window: UIWindow?
    var studyName = ""
    static var studyName = ""
    
    static var homeInstance:HomeVC!
    
    static var gpsRunning: Bool           = false
    static var setupStatus                = false
    static var uploadInProgress           = false
    static var keyboardSetupStatus        = false
    static var pushCheckEnabled           = false
    static var studyVarsImported          = false
    static var memoryWarning              = false
    static var deactivated                = false
    static var gameEnabled                = false
    static var newEMADeliveryDates        = false
    static var updateTimeZone             = false
    static var motionCollectionInProgress = false
    
    static var riskURLString        = ""
    static var s3BucketName         = ""
    static var lastDailyEMARecieved = ""
    static var lastRiskEMARecieved  = ""
    static var lastTimeZone         = ""
    
    static var lastUploadTime: Int64       = 0
    static var lastSelfieExtraction: Int64 = 0
    static var lastScheduledEMADatetime: Int64 = 0
    static var lastScheduledDailyEMADatetime: Int64 = 0
    static var lastScheduledRiskEMADatetime: Int64 = 0
    static var lastCompletedEMADatetime: Int64 = 0
    static var lastCompletedIntensiveEMADateTime: Int64 = 0
    static var emaXP: Int64 = 0
    static var emaGameLastUpdated: Int64 = 0
    static var emaRank: Int32 = 1
    static var emaStreakStart: Int64 = 0
    static var lastMotionCollection: Int64 = 0
    static var lastMotionActivityCollection: Int64 = 0
    
    //static var uploadsToday: Int32?
    
    static var requestCount = 0
    
    static var phaseStart:Date? = nil
    static var phaseEnd:Date?   = nil
    static var lastSelfieDate:Date?
    
    static var studyDict:[String:Any?] = [:]
    static var emaLog:[String:[String]]? = [:]
    
    static var uploadgroup = DispatchGroup()
    
    static var gps:            LocationManager         = LocationManager()
    static var motion:         MotionSensorManager     = MotionSensorManager()
    static var mus:            MusicManager            = MusicManager()
    static var ema:            EMAManager              = EMAManager()
    static var selfieCollect:  SelfieCollectionManager = SelfieCollectionManager()
    static var call:           CallManager?
    static var study:          StudyManager?
    //static var debug:        DebugManager            = DebugManager()
    
    static var device_id: String = UIDevice.current.identifierForVendor!.uuidString
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        window?.tintColor = #colorLiteral(red: 0, green: 0.4588235294, blue: 0.8823529412, alpha: 1)
        
        // MARK: AWS initialization
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: COGNITO_REGIONTYPE, identityPoolId: COGNITO_IDENTITY_POOL_ID)
        let configuration = AWSServiceConfiguration(region: COGNITO_REGIONTYPE, credentialsProvider: credentialsProvider)
        AWSServiceManager.default()?.defaultServiceConfiguration = configuration
        
        // MARK: Set setup status
        let setupValuesIndexPath:IndexPath = NSIndexPath(row: 0, section: 0) as IndexPath
        setupCompleteFetchedResultsController = EarsService.shared.getSetupComplete()
        setupCompleteFetchedResultsController.delegate = self
        AppDelegate.setupStatus = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).setupComplete

        // MARK: Check deactivation status
        let isDeactivated:Bool? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).deactivated
        
        if isDeactivated == nil{
            EarsService.shared.setDeactivationStatus(newValue: false)
        }else{
            
            AppDelegate.deactivated = isDeactivated!
            if isDeactivated!{
                let defaults = UserDefaults(suiteName: GROUP_IDENTIFIER)
                //Set for EARSKeyboard (may cause spurious logged message)
                //changing study_name to an empty string will prevent keyboard collection
                defaults?.set("", forKey: "study_name")
                //Send user to deactivation screen.
                let deactivationScreen = storyBoard.instantiateViewController(withIdentifier: "deactivated")
                self.window?.rootViewController = deactivationScreen
                return AWSMobileClient.sharedInstance().interceptApplication(application,didFinishLaunchingWithOptions: launchOptions)
            }
 
        }
        let newEMADeliveryDates: Bool = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).newEMADeliveryDates
        
        let lastTimeZone: String? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastTimeZone
        if lastTimeZone != nil{
            
            if lastTimeZone == ""{
                AppDelegate.lastTimeZone = getTimeZone()
                EarsService.shared.setLastTimeZone(newValue: AppDelegate.lastTimeZone)
            }else{
                
                if lastTimeZone != getTimeZone() {
                    AppDelegate.lastTimeZone = getTimeZone()
                    AppDelegate.updateTimeZone = true
                    EarsService.shared.setLastTimeZone(newValue: AppDelegate.lastTimeZone)
                }else{
                    AppDelegate.lastTimeZone = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastTimeZone!
                }
            }
        }else{
            AppDelegate.lastTimeZone = getTimeZone()
            AppDelegate.updateTimeZone = true
            EarsService.shared.setLastTimeZone(newValue: AppDelegate.lastTimeZone)
        }
        
        // MARK: Assign core data variables
        let scheduledEMADate: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastScheduledEMADatetime
        if scheduledEMADate != nil{
            AppDelegate.lastScheduledEMADatetime = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastScheduledEMADatetime
        }else{
            AppDelegate.lastScheduledEMADatetime = 0
        }
        
        let scheduledDailyEMADate: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastScheduledDailyEMADatetime
        if scheduledDailyEMADate != nil{
            AppDelegate.lastScheduledDailyEMADatetime = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastScheduledDailyEMADatetime
        }else{
            AppDelegate.lastScheduledDailyEMADatetime = 0
        }
        
        let scheduledRiskEMADate: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastScheduledRiskEMADatetime
        if scheduledRiskEMADate != nil{
            AppDelegate.lastScheduledRiskEMADatetime = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastScheduledRiskEMADatetime
        }else{
            AppDelegate.lastScheduledRiskEMADatetime = 0
        }
        
        if !newEMADeliveryDates{
            //print("resetting EMAs")
            AppDelegate.lastScheduledEMADatetime = 0
            AppDelegate.lastScheduledDailyEMADatetime = 0
            AppDelegate.lastScheduledRiskEMADatetime = 0
            
            EarsService.shared.setLastScheduledEMADatetime(newValue: 0)
            EarsService.shared.setLastScheduledDailyEMADatetime(newValue: 0)
            EarsService.shared.setLastScheduledRiskEMADatetime(newValue: 0)

            //This works in AppDelegate.
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
            AppDelegate.newEMADeliveryDates = true
            EarsService.shared.setNewEMADeliveryDates(newValue: true)
        }
        
        let emaXP: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaXP
        if emaXP != nil{
            AppDelegate.emaXP = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaXP
        }else{
            AppDelegate.emaXP = 0
        }
        
        let emaRank: Int32? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaRank
        if emaRank != nil{
            if setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaRank == 0{
                AppDelegate.emaRank = 1
            }else{
                AppDelegate.emaRank = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaRank
            }
        }else{
            AppDelegate.emaRank = 1
        }
        
        let lastCompletedIntensiveEMADateTime: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastCompletedIntensiveEMADateTime
        if lastCompletedIntensiveEMADateTime != nil{
            AppDelegate.lastCompletedIntensiveEMADateTime = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastCompletedIntensiveEMADateTime
        }else{
            AppDelegate.lastCompletedIntensiveEMADateTime = 0
        }
        
        let lastCompletedEMADatetime: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastCompletedEMADatetime
        if lastCompletedEMADatetime != nil{
            AppDelegate.lastCompletedEMADatetime = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastCompletedEMADatetime
        }else{
            AppDelegate.lastCompletedEMADatetime = 0
        }
        
        let emaGameLastUpdated: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaGameLastUpdated
        if emaGameLastUpdated != nil{
            AppDelegate.emaGameLastUpdated = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaGameLastUpdated
        }else{
            AppDelegate.emaGameLastUpdated = 0
        }
        
        let emaStreakStart: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaStreakStart
        if emaStreakStart != nil{
            AppDelegate.emaStreakStart = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaStreakStart
        }else{
            AppDelegate.emaStreakStart = 0
        }
        
        let lastMotionCollection: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastMotionCollection
        if lastMotionCollection != nil{
            AppDelegate.lastMotionCollection = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastMotionCollection
        }else{
            AppDelegate.lastMotionCollection = 0
        }
        
        let lastMotionActivityCollection: Int64? = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastMotionActivityCollection
        if lastMotionActivityCollection != nil{
            AppDelegate.lastMotionActivityCollection = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastMotionActivityCollection
        }else{
            AppDelegate.lastMotionActivityCollection = 0
        }
        
        if setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaLog == nil{
            AppDelegate.emaLog = [:]
        }else{
            AppDelegate.emaLog = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaLog
        }
        
        //Check if the current indentifierForVendor UUID String has changed, if so set the saved version as the device_id
        let device_id_store = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).indentifierForVendor
        if device_id_store != AppDelegate.device_id {
            AppDelegate.device_id = device_id_store!
            //print("Current  device_id:            \(UIDevice.current.identifierForVendor!.uuidString)")
        }
        //print("Original device_id:            \(AppDelegate.device_id)")
        
        
        // MARK: Set currentEMAPhaseStart && currentEMAPhaseEnd
        AppDelegate.phaseStart = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).currentEMAPhaseStart
        AppDelegate.phaseEnd   = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).currentEMAPhaseEnd
        
        //If lastDailyEMARecieved has been registered previously, pull from coredata
        if setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastDailyEMARecieved == nil{
            EarsService.shared.setLastDailyEMARecieved(newValue: "")
            AppDelegate.lastDailyEMARecieved = ""
        }else{
            AppDelegate.lastDailyEMARecieved = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastDailyEMARecieved!
        }
        
        
        //MARK: KEYBOARD SETUP
        setupCompleteFetchedResultsController = EarsService.shared.getKeyboardStepStatus()
        AppDelegate.keyboardSetupStatus = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).keyboardSetup
        //print("keyboardSetupStatus:  \(AppDelegate.keyboardSetupStatus)")
        
        //USERDEFAULTS SETUP
        UserDefaults.standard.set(AppDelegate.getVersionPref(), forKey: "version_pref")
        
        // MARK: STUDY SETUP
        setupCompleteFetchedResultsController = EarsService.shared.getStudyName()
        //setupCompleteFetchedResultsController.delegate = self
        studyName = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).studyName!
        let consentApproved = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).consentComplete
        if studyName.count > 0 && consentApproved{
            AppDelegate.studyVarsImported = true
            //TODO somehow memoize this
            AppDelegate.studyDict["study"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).studyName
            AppDelegate.studyName = studyName
            AppDelegate.studyDict["emaPhaseFrequency"] = Int(setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaPhaseFrequency)
            AppDelegate.studyDict["includedSensors"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).includedSensors
            AppDelegate.studyDict["emaMoodIdentifiers"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaMoodIdentifiers
            AppDelegate.studyDict["emaHoursBetween"] = Int(setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaHoursBetween)
            AppDelegate.studyDict["emaWeekDays"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaWeekDays
            AppDelegate.studyDict["phaseAutoScheduled"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).phaseAutoScheduled
            AppDelegate.studyDict["emaPhaseBreak"] = Int(setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaPhaseBreak)
            AppDelegate.studyDict["emaVariesDuringWeek"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaVariesDuringWeek
            AppDelegate.studyDict["emaWeekDay"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaWeekDay
            AppDelegate.studyDict["emaDailyStart"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaDailyStart
            AppDelegate.studyDict["emaDailyEnd"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).emaDailyEnd
            AppDelegate.studyDict["s3BucketName"] = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).s3BucketName!
            AppDelegate.s3BucketName = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).s3BucketName!
            
            AppDelegate.study = StudyManager()
            AppDelegate.study?.setVariables(studyName: studyName)
            
            //print("\(AppDelegate.studyName.uppercased())")
            if !nonGameStudies.contains(AppDelegate.studyName.uppercased()){
                AppDelegate.gameEnabled = true
            }
            
            
            //Set study specific UserDefaults
            UserDefaults.standard.set(studyName.uppercased(), forKey: "study_pref")
            let defaults = UserDefaults(suiteName: GROUP_IDENTIFIER)
            
            //Set for EARSKeyboard (may cause spurious logged message)
            defaults?.set(studyName, forKey: "study_name")
            defaults?.set(AppDelegate.device_id, forKey: "device_id")
            
            //Check if risk_ema is included in study sensors
            if (AppDelegate.study?.includedSensors["risk_ema"])!{
                if setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastRiskEMARecieved == nil{
                    EarsService.shared.setLastRiskEMARecieved(newValue: "")
                    AppDelegate.lastRiskEMARecieved = ""
                }else{
                    AppDelegate.lastRiskEMARecieved = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastRiskEMARecieved!
                }
                
                if setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).riskURLString == nil{
                    EarsService.shared.setRiskURLString(newValue: "")
                }else{
                    if setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).riskURLString!.count > 0 {
                        AppDelegate.riskURLString = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).riskURLString!
                    }
                }
            }
            
            
        }else{
            UserDefaults.standard.set("-", forKey: "study_pref")
        }
        
        //UPLOAD DATA SETUP
        setupCompleteFetchedResultsController = EarsService.shared.getKeyboardStepStatus()
        //AppDelegate.uploadsToday = Int32(setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).uploadsToday)
        
        setupCompleteFetchedResultsController = EarsService.shared.getKeyboardStepStatus()
        AppDelegate.lastUploadTime = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastUploadTime
        AppDelegate.lastSelfieExtraction = setupCompleteFetchedResultsController.object(at: setupValuesIndexPath).lastSelfieExtraction
        

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: motionAppRefreshIdent,
                using: nil
            ){ (task) in
                self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
            }
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: motionProcessingIdent,
                using: nil
            ){ (task) in
                self.handleProcessingTask(task: task as! BGProcessingTask)
            }
        } else {
            // Fallback on earlier versions
        }
        
        // MARK: Check Setup Status
        if !AppDelegate.setupStatus{
            //NSLog("User has not completed setup. RootViewController set to setup view.")
            var setupScreen: UIViewController
            //check if consent has been completed
            setupCompleteFetchedResultsController = EarsService.shared.getSetupComplete()

            if AppDelegate.keyboardSetupStatus {
                setupScreen = storyBoard.instantiateViewController(withIdentifier: "stepKeyboardSettings")
            }else{
                if consentApproved{
                    setupScreen = storyBoard.instantiateViewController(withIdentifier: "stepZero")
                }else{
                    setupScreen = storyBoard.instantiateViewController(withIdentifier: "buttonNextVC")
                }
            }
            
            self.window?.rootViewController = setupScreen
            
        }else{
            //NSLog("User has completed setup. RootViewController set to the main view.")

            startCallObserver()
            AppDelegate.registerSensors()
            
            //Send user to the main home screen
            let mainScreen = storyBoard.instantiateViewController(withIdentifier: "home")
            AppDelegate.homeInstance = mainScreen as? HomeVC
            self.window?.rootViewController = mainScreen
            
            AppDelegate.registerForPushNotifications()
        }

        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        //print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
        return AWSMobileClient.sharedInstance().interceptApplication(application,didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    @available(iOS 13.0, *)
    private func handleAppRefreshTask(task: BGAppRefreshTask){
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            //print("Task expired.")
        }
        
        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            //NSLog("Accel available!!")
            let recorder = CMSensorRecorder()
            let queue = DispatchQueue(label: "record_accel_handleAppRefreshTask")
            queue.async {
                recorder.recordAccelerometer(forDuration: 60 * 60 * 12)  // Record for 12 hours
            }
            if AppDelegate.lastMotionCollection == 0{
                let currentDateTime = Date()
                AppDelegate.lastMotionCollection = Int64(currentDateTime.timeIntervalSince1970 * 1000)
                EarsService.shared.setLastMotionCollection(newValue: Int64(currentDateTime.timeIntervalSince1970 * 1000))
            }
        }else{
            //print("not available")
        }
        
        if CMMotionActivityManager.isActivityAvailable(){
            if AppDelegate.lastMotionActivityCollection == 0{
                let currentDateTime = Date()
                AppDelegate.lastMotionActivityCollection = Int64(currentDateTime.timeIntervalSince1970 * 1000)
                EarsService.shared.setLastMotionActivityCollection(newValue: Int64(currentDateTime.timeIntervalSince1970 * 1000))
            }
        }

        task.setTaskCompleted(success: true)
        scheduleBackgroundMotionFetch()
    }
    @available(iOS 13.0, *)
    private func handleProcessingTask(task: BGProcessingTask){
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            //print("Task expired.")
        }
        if !AppDelegate.motionCollectionInProgress{
            AppDelegate.motion.writeAccelAndMotion(accelStartEpochMS: AppDelegate.lastMotionCollection, motionStartEpochMS: AppDelegate.lastMotionActivityCollection)
        }

        task.setTaskCompleted(success: true)
        scheduleBackgroundProcessing()
    }
    
    @available(iOS 13.0, *)
    func scheduleBackgroundMotionFetch(){
        let motionFetchTask = BGAppRefreshTaskRequest(identifier: motionAppRefreshIdent)
        //4 hours
        motionFetchTask.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 4)
        do {
            try BGTaskScheduler.shared.submit(motionFetchTask)
            //print("Motion Collection Submitted.")
        } catch {
          NSLog("Unable to submit task: \(error.localizedDescription)")
        }
    }
    @available(iOS 13.0, *)
    func scheduleBackgroundProcessing(){
        let dataProcessingTask = BGProcessingTaskRequest(identifier: motionProcessingIdent)
        //4 hours
        dataProcessingTask.requiresExternalPower = true
        do {
            try BGTaskScheduler.shared.submit(dataProcessingTask)
            //print("Motion Processing Submitted.")
        } catch {
          NSLog("Unable to submit task: \(error.localizedDescription)")
        }
    }

    lazy var functions = Functions.functions()
    
    // MARK: - application(didReceiveRemoteNotification) (FOREGROUND)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the FOREGROUND,

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        //if let messageID = userInfo[gcmMessageIDKey] {
            //print("Message ID: \(messageID)")
        //}
        //print("\(userInfo)")

        //If a notification comes through with this key, pull new study info
        if AppDelegate.homeInstance == nil{
             return
         }
        
        if let getNewStudyContent = userInfo["getNewStudyContent"]{
            let resultString = "\(getNewStudyContent)"
            if resultString == "true"{
                AppDelegate.study?.pullStudyVariables(study: (AppDelegate.study?.study)!)
            }
        }
        
        if let shouldDeactivate = userInfo["deactivate"]{
            let resultString = "\(shouldDeactivate)"
            if resultString == "true"{
                deactivate()
                if AppDelegate.homeInstance != nil{
                    AppDelegate.homeInstance.immediateDeactivation()
                }
            }
        }
        
        
        if let startEMAPhase = userInfo["startEMAPhase"]{
            let resultString = "\(startEMAPhase)"
            if resultString == "true" && AppDelegate.setupStatus{
                let phaseTuple = AppDelegate.study!.getEMAPhaseStartTuple()

                EarsService.shared.setCurrentEMAPhaseStart(newValue: phaseTuple[0])
                EarsService.shared.setCurrentEMAPhaseEnd(newValue: phaseTuple[1])
                AppDelegate.phaseStart =  phaseTuple[0]
                AppDelegate.phaseEnd   =  phaseTuple[1]
                let newEMADate = Int64(AppDelegate.homeInstance.roundUpHour().timeIntervalSince1970 * 1000)
                AppDelegate.lastScheduledEMADatetime = newEMADate
                EarsService.shared.setLastScheduledEMADatetime(newValue: newEMADate)
                
                let center = UNUserNotificationCenter.current()
                center.getPendingNotificationRequests(completionHandler: { notifications in
                    let scheduledNotifications = notifications.filter{$0.content.categoryIdentifier == "ScheduledEMANotification"}
                    let removeList = scheduledNotifications.map{$0.identifier}
                    center.removePendingNotificationRequests(withIdentifiers: removeList)
                })
                
            }
        }

    }
    let outerGroup = DispatchGroup()
    // MARK: - application(didReceiveRemoteNotification) (BACKGROUND)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the BACKGROUND,

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
            //print("Message ID: \(messageID)")
        //}
        //print("\(userInfo)")
        
        
        //If a notification comes through with this key, pull new study info
        //print("\(userInfo)")
        if AppDelegate.homeInstance == nil{
            return
        }
        if let getNewStudyContent = userInfo["getNewStudyContent"]{
            let resultString = "\(getNewStudyContent)"
            if resultString == "true"{
                AppDelegate.study?.pullStudyVariables(study: (AppDelegate.study?.study)!)
            }
        }
        
        if let shouldDeactivate = userInfo["deactivate"]{
            let resultString = "\(shouldDeactivate)"
            if resultString == "true"{
                deactivate()
                if AppDelegate.homeInstance != nil{
                    AppDelegate.homeInstance.immediateDeactivation()
                }
            }
        }
        
        
        if let startEMAPhase = userInfo["startEMAPhase"]{
            let resultString = "\(startEMAPhase)"
            if resultString == "true" && AppDelegate.setupStatus{
                let phaseTuple = AppDelegate.study!.getEMAPhaseStartTuple()

                EarsService.shared.setCurrentEMAPhaseStart(newValue: phaseTuple[0])
                EarsService.shared.setCurrentEMAPhaseEnd(newValue: phaseTuple[1])
                AppDelegate.phaseStart =  phaseTuple[0]
                AppDelegate.phaseEnd   =  phaseTuple[1]
                let newEMADate = Int64(AppDelegate.homeInstance.roundUpHour().timeIntervalSince1970 * 1000)
                AppDelegate.lastScheduledEMADatetime = newEMADate
                EarsService.shared.setLastScheduledEMADatetime(newValue: newEMADate)
                let center = UNUserNotificationCenter.current()
                center.getPendingNotificationRequests(completionHandler: { notifications in
                    let scheduledNotifications = notifications.filter{$0.content.categoryIdentifier == "ScheduledEMANotification"}
                    let removeList = scheduledNotifications.map{$0.identifier}
                    center.removePendingNotificationRequests(withIdentifiers: removeList)
                })
            }
        }
        
        DispatchQueue.global().async{
                self.outerGroup.wait()
                self.outerGroup.enter()
                AppDelegate.updateOnPush() { (success) -> Void in
                    self.outerGroup.leave()
                    AppDelegate.homeInstance.ScheduleOneEMADaily() { (success) -> Void in
                        //print("1 daily EMA scheduled.")
                    }
                    //print("background upload Complete.")
                }
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Store the completion handler.
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }
    
    /// Get the current date for day by day string comparisons.
    ///
    /// - Returns: String of current date in yyyy-MM-dd format
    static func getDay()->String{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        //let date = dateFormatter.date(from: )
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDateTime)
        return dateString
    }
    
    
    /// Get the date exactly 1 week ago for string comparisons.
    ///
    /// - Returns: String of date 7 days ago in yyyy-MM-dd format
    static func getLastWeek()->String{
        let currentDateTime = Date()
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: currentDateTime)
        let dateFormatter = DateFormatter()
        //let date = dateFormatter.date(from: )
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: lastWeek!)
        return dateString
    }
    
    /// Check if it's Wednesday.
    ///
    /// - Returns:
    ///   - true:  It is Wednesday my dudes.
    ///   - false: It is not Wednesday.
    static func itIsWednesday() -> Bool{
        let today = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: today)
        
        //4 is Wednesday
        if components.weekday == 4 {
            return true
        }
        
        return false
    }
    
    /// Check if it's the weekend.
    ///
    /// - Returns:
    ///   - true:  It is the weekend.
    ///   - false: It is not the weekend.
    static func itIsTheWeekend() -> Bool{
        let today = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: today)
        
        //1 is Sunday, 7 is Saturday
        if components.weekday == 1 || components.weekday == 7{
            return true
        }
        
        return false
    }
    
    
    /// Check the timezone locale to determine if the timezone is even or odd hours from GMT.
    ///
    /// - Returns:
    ///   - 0: Even timezone from GMT.
    ///   - 1: Odd timezone from GMT.
    static func checkTimeZone() -> Int{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        dateFormatter.dateFormat = "ZZZZZ"
        var timeZoneString = dateFormatter.string(from: currentDateTime)
        timeZoneString = timeZoneString.replacingOccurrences(of: "-", with: "")
        guard let index = timeZoneString.firstIndex(of: ":") else { return 0 }
        let strippedTZS = String(timeZoneString[..<index])
        if strippedTZS.first == "0"{
            return Int(String(strippedTZS.last!))! % 2
        }
        return Int(String(strippedTZS))! % 2
    }
    
    /// EMA notifications must be sent out on the hour for every 2 hour time period. This function assigns a firebase topic for the correct timezone depending if the current timezone is even or odd. This function should assign properly even during daylight savings time. This however might not work for timezones that differ by less than an hour (e.g. -00:30 )
    static func assignTimezoneTopic(){
        //Make sure this topic is phased out
        if deactivated{
            return
        }
        //Messaging.messaging().unsubscribe(fromTopic: "ears-topic")
        if AppDelegate.checkTimeZone() == 0{
            //Even timezones from GMT
            //Messaging.messaging().subscribe(toTopic: "ears-topic")
            Messaging.messaging().subscribe(toTopic: "ears-even-topic")
            Messaging.messaging().unsubscribe(fromTopic: "ears-odd-topic")
        }else{
            //Odd timezones from GMT
            Messaging.messaging().subscribe(toTopic: "ears-odd-topic")
            Messaging.messaging().unsubscribe(fromTopic: "ears-even-topic")
        }
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        // 1. Convert device token to string
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        //let token = tokenParts.joined()
        // 2. Print device token to use for PNs payloads
        //print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 1. Print out error if PNs registration not successful
        //print("Failed to register for remote notifications with error: \(error)")
    }
    func getTimeZone() -> String{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        if TimeZone.current.secondsFromGMT() == 0{
            return "+00:00"
        }
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        return timeZoneString
    }
    
    /// Sets location preferences for background.
    static func registerSensors(){
        
        if (AppDelegate.gps.locationEnabled()) {
            if #available(iOS 9.0, *) {
                AppDelegate.gps.locationManager.allowsBackgroundLocationUpdates = true
                AppDelegate.gps.locationManager.pausesLocationUpdatesAutomatically = false
            }
        }
    }
    
    
    /// Starts call observer to access call start and stop stats.
    func startCallObserver(){
        if (AppDelegate.study?.includedSensors["call"])!{
            AppDelegate.call = CallManager()
            callObserver = CXCallObserver()
            callObserver.setDelegate(self, queue: nil)
        }
    }
    
    /// Assigns the call manager to nil for use in the event of install deactivation.
    func stopCallObserver(){
        AppDelegate.call = nil
    }
    
    
    
    /// Get the shared instance for core data access.
    ///
    /// - Returns: UIApplication.shared.delegate as! AppDelegate
    static func sharedInstance() -> AppDelegate{
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    
    /// Handles switching view controllers without keeping them in the view heirachy.
    ///
    /// - Parameters:
    ///   - viewControllerToBeDismissed: Current view in the foreground.
    ///   - controllerToBePresented: View controller that will be swapped to.
    func switchControllers(viewControllerToBeDismissed:UIViewController,controllerToBePresented:UIViewController) {
        if (viewControllerToBeDismissed.isViewLoaded && (viewControllerToBeDismissed.view.window != nil)) {
            // viewControllerToBeDismissed is visible
            //First dismiss and then load your new presented controller
            viewControllerToBeDismissed.dismiss(animated: false, completion: {
                self.window?.rootViewController?.present(controllerToBePresented, animated: true, completion: nil)
            })
        } else {
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if AppDelegate.homeInstance != nil {
            //AppDelegate.homeInstance.unloadImages()
            AppDelegate.homeInstance.setStopImage()
        }
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if #available(iOS 9.0, *) {
            AppDelegate.gps.locationManager.allowsBackgroundLocationUpdates = true
            AppDelegate.gps.locationManager.pausesLocationUpdatesAutomatically = false
        }
        if AppDelegate.setupStatus{
            if (AppDelegate.study?.includedSensors["accel"])! {
                if CMSensorRecorder.isAccelerometerRecordingAvailable() {
                    let recorder = CMSensorRecorder()
                    let queue = DispatchQueue(label: "record_accel_DidEnterBackground")
                    queue.async {
                        recorder.recordAccelerometer(forDuration: 60 * 60 * 12)  // Record for 12 hours
                    }
                    //print("\(AppDelegate.lastMotionCollection)")
                    //print("\(AppDelegate.lastMotionActivityCollection)")
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
        }
        if #available(iOS 13.0, *) {
            if AppDelegate.setupStatus{
                if (AppDelegate.study?.includedSensors["accel"])! {
                    //Schedule another in 10 hours
                    scheduleBackgroundMotionFetch()
                    scheduleBackgroundProcessing()
                }
            }
        }
    }
    
    // MARK: - applicationWillEnterForeground
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if AppDelegate.homeInstance != nil{
            NotificationCenter.default.post(name: NSNotification.Name("ReloadNotification"), object: nil)
            
            // Reload images in HomeVC that were removed when entering background to help reduce memory.
            DispatchQueue.main.async {
                AppDelegate.homeInstance.loadImages()
            }
            if AppDelegate.gameEnabled{
                AppDelegate.homeInstance.updateEMAScore()
            }
            
            let queue = DispatchQueue(label: "appDel_foreground")
            //If the photo library was authorized because selfies collection is included in the study, collect selfies
            if Date(timeIntervalSince1970: Double(AppDelegate.lastUploadTime / 1000)) < Calendar.current.date(byAdding: .hour, value: -1, to: Date())!{
                AppDelegate.updateOnPush() { (success) -> Void in
                    //NSLog("upload complete")
                    AppDelegate.homeInstance.batchScheduleEMADaily() { (success) -> Void in
                        //Check if Risk EMAs need to be scheduled.
                        if (AppDelegate.study?.includedSensors["risk_ema"])!{
                            AppDelegate.homeInstance.batchScheduleEMARisk() { (success) -> Void in
                                AppDelegate.homeInstance.batchScheduleEMA() { (success) -> Void in
                                    queue.asyncAfter(deadline: .now() + TimeInterval(1), execute:{
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
                            AppDelegate.homeInstance.batchScheduleEMA() { (success) -> Void in
                                
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
                AppDelegate.homeInstance.batchScheduleEMADaily() { (success) -> Void in
                    //Check if Risk EMAs need to be scheduled.
                    if (AppDelegate.study?.includedSensors["risk_ema"])!{
                        AppDelegate.homeInstance.batchScheduleEMARisk() { (success) -> Void in
                            AppDelegate.homeInstance.batchScheduleEMA() { (success) -> Void in
                                queue.asyncAfter(deadline: .now() + TimeInterval(1), execute:{
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
                        AppDelegate.homeInstance.batchScheduleEMA() { (success) -> Void in
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
    }
    
    // MARK: - startSensors
    /// Restart device motion and location services.
    static func startSensors(){
        
        if(AppDelegate.gps.locationEnabled() && !AppDelegate.deactivated){
            AppDelegate.gpsRunning = true
            AppDelegate.gps.locationManager.allowsBackgroundLocationUpdates = true
            AppDelegate.gps.locationManager.pausesLocationUpdatesAutomatically = false
            AppDelegate.gps.startLocationUpdates()
        }else{
            AppDelegate.gpsRunning = false
            AppDelegate.gps.stopLocationUpdates()
        }
    }
    
    // MARK: - applicationDidBecomeActive
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if AppDelegate.homeInstance != nil{
            AppDelegate.homeInstance.loadImages()
            AppDelegate.homeInstance.checkAvailableEMAs()
            if AppDelegate.deactivated{
                AppDelegate.homeInstance.immediateDeactivation()
                AppDelegate.homeInstance = nil
            }
        }
        
        //AppDelegate.motion.stopDeviceMotion()
        //AppDelegate.motion.startDeviceMotion()
        
        if(AppDelegate.gps.locationEnabled() && !AppDelegate.deactivated){
            AppDelegate.gpsRunning = true
            AppDelegate.gps.locationManager.allowsBackgroundLocationUpdates = true
            AppDelegate.gps.locationManager.pausesLocationUpdatesAutomatically = false
            AppDelegate.gps.startLocationUpdates()
        }else{
            AppDelegate.gpsRunning = false
            AppDelegate.gps.stopLocationUpdates()
        }
        
    }

    /// Get the current version of the App as a string.
    ///
    /// - Returns: App version number.
    static func getVersionPref()->String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        return version
    }
    
    // MARK: - applicationWillTerminate
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        //try to not lose any data from the buffer
        AppDelegate.motion.stopDeviceMotion()
        //AppDelegate.motion.forceWriteBuffer()
        //NSLog("I'll be back 🤖.")
    }
    
    // MARK: - applicationDidReceiveMemoryWarning
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        //NSLog("Memory warning ahhhh")
        
        //AppDelegate.motion.stopDeviceMotion()
        //AppDelegate.motion.forceWriteBuffer()
        
        //NSLog("Memory warning ahhhh")
    }
    
    /// Ask for Media Library access for accessing playing music.
    public static func requestMusicAccess(){
        if (MPMediaLibrary.authorizationStatus() == MPMediaLibraryAuthorizationStatus.notDetermined) {
            
            // Access has not been determined.
            MPMediaLibrary.requestAuthorization({ (status: MPMediaLibraryAuthorizationStatus) in
                
                if (status == MPMediaLibraryAuthorizationStatus.authorized) {
                    //NSLog("\(status)")
                }else{
                    //NSLog("\(status)")
                }
            })
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "EARS")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    
    /// Handle changing the root view controller with an animation.
    ///
    /// - Parameter identifier: storyboard identifier for the new root view controller.
    func changeRootViewController(with identifier:String!) {
        let storyboard = self.window?.rootViewController?.storyboard
        let desiredViewController = storyboard?.instantiateViewController(withIdentifier: identifier);
        
        let snapshot:UIView = (self.window?.snapshotView(afterScreenUpdates: true))!
        desiredViewController?.view.addSubview(snapshot);
        
        self.window?.rootViewController = desiredViewController;
        
        UIView.animate(withDuration: 0.3, animations: {() in
            snapshot.layer.opacity = 0;
            snapshot.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5);
        }, completion: {
            (value: Bool) in
            snapshot.removeFromSuperview();
        });
    }
    
    
    /// Setup push notifications.
    static func registerForPushNotifications() {

        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            //UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        
        UIApplication.shared.registerForRemoteNotifications()
 
    }
    
    
    /// Sets current epoch timestamp for lastUploadTime and sets the new value in coredata.
    static func updateLastUploadTime(){
        let currentDateTime = Int64(Date().timeIntervalSince1970 * 1000)

        EarsService.shared.setLastUploadTime(newValue: currentDateTime)
        AppDelegate.lastUploadTime = currentDateTime
        //print("last upload time updated:\(AppDelegate.lastUploadTime)")
        
    }

    static var innerGroup = DispatchGroup()
    // MARK: - upload()
    /// Uploads sensor files to AWS. Uploads will not occur if setup has not completed, if EARS has been deactivated, or if there is no internet connection.
    static func upload(){
        //print("upload started")
        if AppDelegate.setupStatus == false{
            //NSLog("setup has not complete, unable to upload")
            AppDelegate.uploadgroup.leave()
            return
        }
        if AppDelegate.motionCollectionInProgress{
            //NSLog("Motion Collection in progress, defering upload.")
            AppDelegate.uploadgroup.leave()
            return
        }
        if AppDelegate.deactivated{
            //NSLog("deactivated, unable to upload")
            AppDelegate.uploadgroup.leave()
            return
        }
        
        let queue = DispatchQueue(label: "SerialQueueUpload")
        //let innerGroup = DispatchGroup()
        //Pull the latest data
        let netState = NetworkReachabilityManager.shared.getNetworkState()
        
        if netState == "none"{
            //NSLog("Unable to upload files at this time. NetState : \(netState)")
            AppDelegate.uploadgroup.leave()
            return
        }
        
        queue.async {
            //Accel & Gyro are the only two sensors that require a force write.
            AppDelegate.ema.recordEMALog()
            /*
            AppDelegate.innerGroup.enter()
            AppDelegate.motion.forceWriteBuffer() { (success) -> Void in
                innerGroup.leave()
            }
            //print("start wait")
            AppDelegate.innerGroup.wait()
            //print("end wait")
            */
            let uploadTime = UploadData()
            uploadTime.gigaUploadData()
        }
        //AppDelegate.uploadgroup.wait()
        
        DispatchQueue.main.async{
            AppDelegate.updateLastUploadTime()
        }
        
    }

    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    private var setupCompleteFetchedResultsController: NSFetchedResultsController<SetupComplete>!
    
    
    // MARK: - updateOnPush
    /// Updates important study variables and then attempts to upload available sensor files.
    static func updateOnPush(completion: @escaping (_ success: Bool) -> Void){
        //NSLog("Push")
        
        DispatchQueue.global().async{
            AppDelegate.uploadgroup.enter()
            
            //If app has been setup, start upload
            if(AppDelegate.setupStatus){
                //NSLog("upload")
                upload()
            }else{
                AppDelegate.uploadgroup.leave()
            }
            
            AppDelegate.uploadgroup.notify(queue: .global(), execute: {
                if(AppDelegate.setupStatus){
                    //restart sensors
                    //AppDelegate.motion.startDeviceMotion()
                    startSensors()
                    
                    DispatchQueue.main.async {
                        if AppDelegate.homeInstance != nil{
                            
                            if (AppDelegate.study?.includedSensors["risk_ema"])!{
                                if AppDelegate.riskURLString.count > 0{
                                    AppDelegate.homeInstance.sendFollowupRiskEMARequest(riskURLString: AppDelegate.riskURLString)
                                }
                            }
                            
                            
                            if AppDelegate.phaseStart != nil && AppDelegate.phaseEnd != nil{
                                let currentDate = Date()
                                //print("\(AppDelegate.phaseStart) < \(Date()) < \(AppDelegate.phaseEnd) \(AppDelegate.study?.phaseAutoScheduled)")
                                
                                //If there is an autoschedule between phases, and phaseEnd is over.
                                if AppDelegate.phaseStart! < currentDate && AppDelegate.phaseEnd! < currentDate && (AppDelegate.study?.phaseAutoScheduled)!{
                                    let phaseTuple = AppDelegate.study!.setNextEMAPhaseTuple()
                                    EarsService.shared.setCurrentEMAPhaseStart(newValue: phaseTuple[0])
                                    EarsService.shared.setCurrentEMAPhaseEnd(newValue: phaseTuple[1])
                                    let newEMADate = Int64(AppDelegate.homeInstance.getDayStart(with: phaseTuple[0]).timeIntervalSince1970 * 1000)
                                    AppDelegate.lastScheduledEMADatetime = newEMADate
                                    EarsService.shared.setLastScheduledEMADatetime(newValue: newEMADate)
                                }
                            }
                            
                            completion(true)
                        }else{
                            completion(true)
                        }
                        
                    }
                    
                }
                
            })
        }
        
    }
    
    /// Deactivate EARS sensor collection and unsubscribes from firebase EMA notifications.
    func deactivate(){
        EarsService.shared.setDeactivationStatus(newValue: true)
        AppDelegate.deactivated = true
        AppDelegate.motion.stopDeviceMotion()
        AppDelegate.gps.stopLocationUpdates()
        
        stopCallObserver()
        
        Messaging.messaging().unsubscribe(fromTopic: "ears-topic")
        Messaging.messaging().unsubscribe(fromTopic: "ears-odd-topic")
        Messaging.messaging().unsubscribe(fromTopic: "ears-even-topic")
        
        let defaults = UserDefaults(suiteName: GROUP_IDENTIFIER)
        defaults?.set("", forKey: "study_name")
    }
    
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // MARK: - userNotificationCenter (FOREGROUND)
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if AppDelegate.homeInstance == nil{
            return
        }
        // Handle non-silent push notifications when the apps is in the FORGROUND.
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
            //print("Message ID: \(messageID)")
        //}
        if let getNewStudyContent = userInfo["getNewStudyContent"]{
            let resultString = "\(getNewStudyContent)"
            if resultString == "true"{
                AppDelegate.study?.pullStudyVariables(study: (AppDelegate.study?.study)!)
            }
        }
        
        if let uploadForUser = userInfo["upload"]{
            let resultString = "\(uploadForUser)"
            if resultString == "true"{

                DispatchQueue.global().async{
                        
                    self.outerGroup.wait()
                    self.outerGroup.enter()
                    AppDelegate.updateOnPush() { (success) -> Void in
                        self.outerGroup.leave()
                    }
                    
                }
            }
        }
        
        if let shouldDeactivate = userInfo["deactivate"]{
            let resultString = "\(shouldDeactivate)"
            if resultString == "true"{
                //NSLog("getNewStudyContent: true")
                deactivate()
                if AppDelegate.deactivated && AppDelegate.homeInstance != nil{
                    AppDelegate.homeInstance.immediateDeactivation()
                }
            }
        }
        
        if let startEMAPhase = userInfo["startEMAPhase"]{
            let resultString = "\(startEMAPhase)"
            if resultString == "true" && AppDelegate.setupStatus{
                let phaseTuple = AppDelegate.study!.getEMAPhaseStartTuple()
                EarsService.shared.setCurrentEMAPhaseStart(newValue: phaseTuple[0])
                EarsService.shared.setCurrentEMAPhaseEnd(newValue: phaseTuple[1])
                AppDelegate.phaseStart =  phaseTuple[0]
                AppDelegate.phaseEnd   =  phaseTuple[1]
                //Start In the next two hour window.
                let newEMADate = Int64(AppDelegate.homeInstance.roundUpHour().timeIntervalSince1970 * 1000)
                AppDelegate.lastScheduledEMADatetime = newEMADate
                EarsService.shared.setLastScheduledEMADatetime(newValue: newEMADate)
                center.getPendingNotificationRequests(completionHandler: { notifications in
                    let scheduledNotifications = notifications.filter{$0.content.categoryIdentifier == "ScheduledEMANotification"}
                    let removeList = scheduledNotifications.map{$0.identifier}
                    
                    center.removePendingNotificationRequests(withIdentifiers: removeList)
                })
            }
        }
        
        // Print full message.
        //print("user1: \(userInfo)")
        if AppDelegate.homeInstance != nil{
            AppDelegate.homeInstance.removedOldEMAs{ (success) -> Void in
                
            }
        }
        if AppDelegate.homeInstance != nil{
            if !HomeVC.emaActive{
                if notification.request.content.categoryIdentifier == "DailyEMANotification"{
                    AppDelegate.homeInstance.getMostRecentDeliveredDaily(currentNotification: notification, completion: { (success) in
                        DispatchQueue.main.async {
                            if AppDelegate.homeInstance.checkValidDailyEMA(for: success.date){
                                AppDelegate.study?.startDailyEMA(ident: success.request.identifier)
                                //AppDelegate.homeInstance.startDailyEMASurvey(identifier: success.request.identifier)
                            }else{
                                AppDelegate.homeInstance.presentInvalidEMADialog()
                            }
                        }

                    })
                }
                if notification.request.content.categoryIdentifier == "RiskEMANotification"{
                    AppDelegate.homeInstance.getMostRecentDeliveredRisk(currentNotification: notification, completion: { (success) in
                        DispatchQueue.main.async {
                            if AppDelegate.homeInstance.checkRiskEMAStart() && AppDelegate.itIsWednesday(){
                                AppDelegate.study?.startRiskEMA(ident: success.request.identifier)
                                //AppDelegate.homeInstance.startRiskEMASurvey(identifier: success.request.identifier)
                            }else{
                                AppDelegate.homeInstance.presentInvalidEMADialog()
                            }
                        }

                    })
                }
                if notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
                    AppDelegate.homeInstance.getMostRecentDelivered(currentNotification: notification, completion: { (success) in
                        DispatchQueue.main.async {
                            if AppDelegate.homeInstance.checkValidEMA(for: success.date){
                                AppDelegate.study?.startIntensiveEMA(ident: success.request.identifier)
                                //AppDelegate.homeInstance.startSurvey(identifier: success.request.identifier)
                            }else{
                                AppDelegate.homeInstance.presentInvalidEMADialog()
                            }
                        }
                        
                    })
                }
            }else{
                if notification.request.content.categoryIdentifier == "DailyEMANotification"{
                    HomeVC.suddenEMA.append(notification.request.content.categoryIdentifier)
                    HomeVC.suddenEMAIdents.append(notification.request.identifier)
                }
                if notification.request.content.categoryIdentifier == "RiskEMANotification"{
                    HomeVC.suddenEMA.append(notification.request.content.categoryIdentifier)
                    HomeVC.suddenEMAIdents.append(notification.request.identifier)
                }
                if notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
                    HomeVC.suddenEMA.append(notification.request.content.categoryIdentifier)
                    HomeVC.suddenEMAIdents.append(notification.request.identifier)
                }
                
            }
        }
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    // MARK: - userNotificationCenter (BACKGROUND)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle non-silent push notifications when the apps is in the BACKGROUND.
        if AppDelegate.homeInstance == nil{
            return
        }
        
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
            //print("Message ID: \(messageID)")
        //}
        //If a notification comes through with this key, pull new study info
        if let getNewStudyContent = userInfo["getNewStudyContent"]{
            let resultString = "\(getNewStudyContent)"
            if resultString == "true"{
                AppDelegate.study?.pullStudyVariables(study: (AppDelegate.study?.study)!)
            }
        }
        
        if let shouldDeactivate = userInfo["deactivate"]{
            let resultString = "\(shouldDeactivate)"
            if resultString == "true"{
                deactivate()
            }
        }
        
        if let uploadForUser = userInfo["upload"]{
            let resultString = "\(uploadForUser)"
            if resultString == "true"{
                DispatchQueue.global().async{
                    self.outerGroup.wait()
                    self.outerGroup.enter()
                    AppDelegate.updateOnPush() { (success) -> Void in
                        self.outerGroup.leave()
                    }
                }
            }
        }
        
        if let startEMAPhase = userInfo["startEMAPhase"]{
            let resultString = "\(startEMAPhase)"
            if resultString == "true" && AppDelegate.setupStatus{
                let phaseTuple = AppDelegate.study!.getEMAPhaseStartTuple()
                EarsService.shared.setCurrentEMAPhaseStart(newValue: phaseTuple[0])
                EarsService.shared.setCurrentEMAPhaseEnd(newValue: phaseTuple[1])
                AppDelegate.phaseStart =  phaseTuple[0]
                AppDelegate.phaseEnd   =  phaseTuple[1]
                //Start in the next two hour window.
                let newEMADate = Int64(AppDelegate.homeInstance.roundUpHour().timeIntervalSince1970 * 1000)
                //let newEMADate = Int64(AppDelegate.homeInstance.getDayStart(with: phaseTuple[0]).timeIntervalSince1970 * 1000)
                AppDelegate.lastScheduledEMADatetime = newEMADate
                EarsService.shared.setLastScheduledEMADatetime(newValue: newEMADate)
                center.getPendingNotificationRequests(completionHandler: { notifications in
                    let scheduledNotifications = notifications.filter{$0.content.categoryIdentifier == "ScheduledEMANotification"}
                    let removeList = scheduledNotifications.map{$0.identifier}
                    center.removePendingNotificationRequests(withIdentifiers: removeList)
                })
            }
        }
        
        // Print full message.
        //print("user2: \(userInfo)")
        if AppDelegate.homeInstance != nil{
            AppDelegate.homeInstance.removedOldEMAs{ (success) -> Void in
                
            }
        }
        if AppDelegate.homeInstance != nil{
            if response.notification.request.content.categoryIdentifier == "DailyEMANotification"{
                AppDelegate.homeInstance.getMostRecentDeliveredDaily(currentNotification: response.notification, completion: { (success) in
                    DispatchQueue.main.async {
                        if AppDelegate.homeInstance.checkValidDailyEMA(for: success.date){
                            AppDelegate.study?.startDailyEMA(ident: success.request.identifier)
                            //AppDelegate.homeInstance.startDailyEMASurvey(identifier: success.request.identifier)
                        }else{
                            AppDelegate.homeInstance.presentInvalidEMADialog()

                        }
                    }

                })
            }
            if response.notification.request.content.categoryIdentifier == "RiskEMANotification"{
                AppDelegate.homeInstance.getMostRecentDeliveredRisk(currentNotification: response.notification, completion: { (success) in
                    DispatchQueue.main.async {
                        if AppDelegate.homeInstance.checkRiskEMAStart() && AppDelegate.itIsWednesday(){
                            AppDelegate.study?.startRiskEMA(ident: success.request.identifier)
                            //AppDelegate.homeInstance.startRiskEMASurvey(identifier: success.request.identifier)
                        }else{
                            AppDelegate.homeInstance.presentInvalidEMADialog()
                        }
                    }

                })
            }
            if response.notification.request.content.categoryIdentifier == "ScheduledEMANotification"{
                AppDelegate.homeInstance.getMostRecentDelivered(currentNotification: response.notification, completion: { (success) in
                    DispatchQueue.main.async {
                        if AppDelegate.homeInstance.checkValidEMA(for: success.date){
                            AppDelegate.study?.startIntensiveEMA(ident: success.request.identifier)
                            //AppDelegate.homeInstance.startSurvey(identifier: success.request.identifier)
                        }else{
                            AppDelegate.homeInstance.presentInvalidEMADialog()
                        }
                    }
                })
            }
        }
        completionHandler()
    }
}

extension CMSensorDataList: Sequence {
    public typealias Iterator = NSFastEnumerationIterator
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        //print("Firebase registration token: \(fcmToken)")
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        AppDelegate.assignTimezoneTopic()
        //Messaging.messaging().subscribe(toTopic: "ears-topic")
        if studyName.count > 0{
            Messaging.messaging().subscribe(toTopic: studyName)
        }
        if UIDevice.current.identifierForVendor!.uuidString != AppDelegate.device_id{
            Messaging.messaging().subscribe(toTopic: UIDevice.current.identifierForVendor!.uuidString)
            //might as well check who's gone ghost
            Messaging.messaging().subscribe(toTopic: "ghosts")
        }
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        //print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
