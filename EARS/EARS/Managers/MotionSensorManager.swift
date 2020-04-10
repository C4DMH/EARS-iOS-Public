//
//  AccelManager.swift
//  EARS
//
//  Created by Wyatt Reed on 7/27/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import CoreMotion
import SwiftProtobuf


class MotionSensorManager {
    
    var accelDataString = "ACCEL"
    var gyroDataString = "GYRO"
    var motionActivityDataString = "MotionActivity"

    var protoDataA: [Research_AccelGyroEvent] = []
    var protoDataG: [Research_AccelGyroEvent] = []
    var protoDataMA: [Research_MotionActivityEvent] = []

    var lastAccelerationA: Double = 0.0
    var lastAccelerationG: Double = 0.0
    
    let motionKit = MotionKit()
    
    
    
    /**
     Returns a Bool value indicating whether Accelerometer is Available.
     - returns: true or false
     */
    
    func accelEnabled() -> Bool {
        var accelRequested:Bool? = false
        
        if AppDelegate.study != nil && AppDelegate.setupStatus && !AppDelegate.deactivated{
            accelRequested = (AppDelegate.study?.includedSensors["accel"])! && AppDelegate.setupStatus
        }
        return motionKit.manager.isAccelerometerAvailable && motionKit.manager.isDeviceMotionAvailable && accelRequested!
    }
    
    func gyroEnabled() -> Bool {
        var gyroRequested:Bool? = false
        
        if AppDelegate.study != nil && AppDelegate.setupStatus && !AppDelegate.deactivated{
            gyroRequested = (AppDelegate.study?.includedSensors["gyro"])! && AppDelegate.setupStatus
        }
        
        return motionKit.manager.isGyroAvailable && motionKit.manager.isDeviceMotionAvailable && gyroRequested!
    }
    //DEPRECATED, NO LONGER USED
    func startDeviceMotion() {
        if accelEnabled(){
            let dataStorageA = DataStorage()
            //10hz (10 samples per second)
            //motionKit.getAccelerationFromDeviceMotion(interval: 0.1){
            motionKit.getAccelerometerValues(interval: 0.1){
                (x,y,z) in
                let accel = (x*x + y*y + z*z).squareRoot()
                //Record updates only if the acceleration has changed by 1 decimal place.
                if (accel * 100).rounded() != self.lastAccelerationA{
                    // Use the motion data in your app.
                    //let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
                    //let line = "\(currentDateTime),x: \(String(format: "%.10f", x)),y: \(String(format: "%.10f", y)),z: \(String(format: "%.10f", z)) "
                    //NSLog(" ACCEL : \(line)")

                    let accelProtoBuf = Research_AccelGyroEvent.with {
                        $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                        $0.x = Float(x)
                        $0.y = Float(y)
                        $0.z = Float(z)
                    }
                    
                    self.protoDataA.append(accelProtoBuf)
                    //NSLog("buffer count: \(self.protoDataA.count)")
                    if self.protoDataA.count >= 100{
                        //print("accel file written")
                        
                        dataStorageA.writeFileProto(dataType: self.accelDataString, messageArray: self.protoDataA)
                        self.protoDataA = []
                    }
                    self.lastAccelerationA = (accel * 100).rounded()
                }
            }
        }
        if gyroEnabled(){
            let dataStorageG = DataStorage()
            //10hz (10 samples per second)
            //motionKit.getRotationRateFromDeviceMotion(interval:  0.1){
            motionKit.getGyroValues(interval:  0.1){
                (x,y,z) in
                let accel = (x*x + y*y + z*z).squareRoot()
                //Record updates only if the acceleration has changed by 1 decimal place.
                if (accel * 10).rounded() != self.lastAccelerationG{
                    // Use the motion data in your app.
                    //let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
                    //let line = "\(currentDateTime),x: \(String(format: "%.10f", x)),y: \(String(format: "%.10f", y)),z: \(String(format: "%.10f", z)) "
                    //NSLog(" GYRO : \(line)")
                    
                    let gyroProtoBuf = Research_AccelGyroEvent.with {
                        $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                        $0.x = Float(x)
                        $0.y = Float(y)
                        $0.z = Float(z)
                    }
                    
                    self.protoDataG.append(gyroProtoBuf)
                    //NSLog("buffer count: \(self.protoDataG.count)")
                    if self.protoDataG.count >= 100{
                    
                        dataStorageG.writeFileProto(dataType: self.gyroDataString, messageArray: self.protoDataG)
                        self.protoDataG = []
                    }
                    self.lastAccelerationG = (accel * 10).rounded()
                }
            }
            
        }
 
    }
    
    func stopDeviceMotion() {
        motionKit.stopAccelerometerUpdates()
        motionKit.stopGyroUpdates()
    }
    
    //DEPRECATED, NO LONGER USED
    func forceWriteBuffer(completion: @escaping (_ success: Bool) -> Void){
        
        //Watchout for multithreading here!!!!!
        if self.protoDataA.count > 0 && !AppDelegate.deactivated{
            let dataStorageA = DataStorage()
            dataStorageA.writeFileProto(dataType: self.accelDataString, messageArray: self.protoDataA)
            self.protoDataA = []
        }
        
        if self.protoDataG.count > 0 && !AppDelegate.deactivated{
            let dataStorageG = DataStorage()
            dataStorageG.writeFileProto(dataType: self.gyroDataString, messageArray: self.protoDataG)
            self.protoDataG = []
        }
        
        completion(true)

    }
    
    func writeAccelBatch(startEpoch: Double, endEpoch: Double, completion: @escaping (_ success: Bool) -> Void){
        let startDate = Date(timeIntervalSince1970: startEpoch)
        let endDate = Date(timeIntervalSince1970: endEpoch)
        
        let group = DispatchGroup()
        //NSLog("Accel write initiated.")
        defer {
            //NSLog("Accel write Complete.")
            DispatchQueue.global(qos: .background).sync{ [weak self] in
                guard let self = self else {
                    completion(false)
                    return
                }
                let dataStorageA = DataStorage()
                group.enter()
                dataStorageA.writeMotionFileProto(dataType: self.accelDataString, messageArray: self.protoDataA){ (success) -> Void in
                    self.protoDataA = []
                    AppDelegate.lastMotionCollection = Int64(endEpoch * 1000)
                    EarsService.shared.setLastMotionCollection(newValue: Int64(endEpoch * 1000))
                    group.leave()
                }
                group.wait()
                completion(true)
            }
        }
        DispatchQueue.global(qos: .background).sync{ [weak self] in
            guard let self = self else {
                return
            }
            //Pull data since the lastMotionCollection
            if let list = CMSensorRecorder().accelerometerData(from: startDate, to: endDate){
                //NSLog("   ..Begin write to proto..")
                for data in list{
                    if let accData = data as? CMRecordedAccelerometerData{
                        let accelProtoBuf = Research_AccelGyroEvent.with {
                            $0.timestamp = Int64(accData.startDate.timeIntervalSince1970 * 1000)
                            $0.x = Float(accData.acceleration.x)
                            $0.y = Float(accData.acceleration.y)
                            $0.z = Float(accData.acceleration.z)
                        }
                        self.protoDataA.append(accelProtoBuf)
                    }
                }
            }
        }
        
    }
    
    func collectMotionEvents(startEpoch: Double, endEpoch: Double,completion: @escaping (_ success: Bool) -> Void){
        let startDate = Date(timeIntervalSince1970: startEpoch)
        let endDate = Date(timeIntervalSince1970: endEpoch)
        if CMMotionActivityManager.isActivityAvailable() {
            //NSLog("Motion Activity available!!")
            let recorder = CMMotionActivityManager()
            let currentDateTime = Date()
            let group = DispatchGroup()
            
            DispatchQueue.global(qos: .background).sync{ [weak self] in
                guard let self = self else {
                    return
                }
                recorder.queryActivityStarting(from: startDate, to: endDate, to: .main) {  motionActivities, error in
                    if let error = error {
                        NSLog("error: \(error.localizedDescription)")
                        return
                    }
                    defer {
                        //NSLog("Motion Activity write Complete.")
                        DispatchQueue.global(qos: .background).sync{ [weak self] in
                            guard let self = self else {
                                completion(false)
                                return
                            }
                            group.enter()
                            let dataStorageMA = DataStorage()
                            dataStorageMA.writeMotionFileProto(dataType: self.motionActivityDataString, messageArray: self.protoDataMA){ (success) -> Void in
                                self.protoDataMA = []
                                AppDelegate.lastMotionActivityCollection = Int64(endEpoch * 1000)
                                EarsService.shared.setLastMotionActivityCollection(newValue: Int64(endEpoch * 1000))
                                group.leave()
                            }
                            group.wait()
                            completion(true)
                        }
                    }
                    motionActivities?.forEach { activity in
                        let motionActivityProtoBuf = Research_MotionActivityEvent.with {
                            $0.timestamp = Int64(activity.startDate.timeIntervalSince1970 * 1000)
                            $0.confidence = {
                                switch activity.confidence {
                                case .low:
                                    return .low
                                case .medium:
                                    return .medium
                                case .high:
                                    return .high
                                default:
                                    //This shouldn't happen unless the API changes
                                    return .unknown
                                }
                            }()
                            $0.stationary = {
                                switch activity.stationary {
                                case true:
                                    return true
                                case false:
                                    return false
                                }
                            }()
                            $0.walking = {
                                switch activity.walking {
                                case true:
                                    return true
                                case false:
                                    return false
                                }
                            }()
                            $0.running = {
                                switch activity.running {
                                case true:
                                    return true
                                case false:
                                    return false
                                }
                            }()
                            $0.automotive = {
                                switch activity.automotive {
                                case true:
                                    return true
                                case false:
                                    return false
                                }
                            }()
                            $0.cycling = {
                                switch activity.cycling {
                                case true:
                                    return true
                                case false:
                                    return false
                                }
                            }()
                            $0.unknown = {
                                switch activity.unknown {
                                case true:
                                    return true
                                case false:
                                    return false
                                }
                            }()
                        }
                        //print("new event")
                        
                        self.protoDataMA.append(motionActivityProtoBuf)
                   }
                }
            }
        }else{
            //NSLog("Motion Activity not available.")
            completion(false)
        }
    }
    
    func writeAccelAndMotion(accelStartEpochMS: Int64, motionStartEpochMS: Int64){
        let currentTime = Date()
        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            let outerGroup = DispatchGroup()
            AppDelegate.motionCollectionInProgress = true
            var startEpoch = Double(accelStartEpochMS / 1000)
            if Date(timeIntervalSince1970: startEpoch) < Calendar.current.date(byAdding: .day, value: -3, to: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)!{
                //set epoch to 2 days 23 hours and 30 minutes ago since date older than 3 days
                startEpoch = Calendar.current.date(byAdding: .day, value: -3, to: Date())!.timeIntervalSince1970 + 1800
            }
            //Add 15 minutes
            var endEpoch = startEpoch + 900
            
            if endEpoch >= currentTime.timeIntervalSince1970{
                endEpoch = currentTime.timeIntervalSince1970
            }
            
            DispatchQueue.global(qos: .background).async{ [weak self] in
               guard let self = self else {
                 return
               }
                
                while startEpoch < currentTime.timeIntervalSince1970{
                    outerGroup.enter()
                    //print("starting new accel write.")
                    self.writeAccelBatch(startEpoch: startEpoch, endEpoch: endEpoch){ (success) -> Void in
                        startEpoch = startEpoch + 900
                        endEpoch = endEpoch + 900
                        if endEpoch >= currentTime.timeIntervalSince1970{
                            endEpoch = currentTime.timeIntervalSince1970
                        }
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2, execute: {
                            outerGroup.leave()
                        })
                    }
                    outerGroup.wait()
                }
                if CMMotionActivityManager.isActivityAvailable(){
                    var motionStartEpoch = Double(motionStartEpochMS / 1000)
                    if Date(timeIntervalSince1970: motionStartEpoch) < Calendar.current.date(byAdding: .day, value: -3, to: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)!{
                        //set epoch to 2 days 23 hours and 30 minutes ago since date older than 3 days
                        motionStartEpoch = Calendar.current.date(byAdding: .day, value: -3, to: Date())!.timeIntervalSince1970 + 1800
                    }
                    self.collectMotionEvents(startEpoch: motionStartEpoch, endEpoch: currentTime.timeIntervalSince1970){ (success) -> Void in
                        AppDelegate.motionCollectionInProgress = false
                        //print("done c:")
                    }
                }else{
                    AppDelegate.motionCollectionInProgress = false
                }
            }
        }else{
            if CMMotionActivityManager.isActivityAvailable(){
                AppDelegate.motionCollectionInProgress = true
                
                var motionStartEpoch = Double(motionStartEpochMS / 1000)
                if Date(timeIntervalSince1970: motionStartEpoch) < Calendar.current.date(byAdding: .day, value: -3, to: Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)!{
                    //set epoch to 2 days 23 hours and 30 minutes ago since date older than 3 days
                    motionStartEpoch = Calendar.current.date(byAdding: .day, value: -3, to: Date())!.timeIntervalSince1970 + 1800
                }
                self.collectMotionEvents(startEpoch: Double(motionStartEpochMS / 1000), endEpoch: currentTime.timeIntervalSince1970){ (success) -> Void in
                    AppDelegate.motionCollectionInProgress = false
                    //print("done c:")
                }
            }
        }
    }
    
    
    
}
class MotionOperations {
    lazy var collectionInProgress: [IndexPath: Operation] = [:]
    lazy var collectionQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Collection queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
}
class MotionCollector: Operation {
    
}
