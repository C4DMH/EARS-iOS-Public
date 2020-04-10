//
//  SelfieCollectionManager.swift
//  EARS
//
//  Created by Wyatt Reed on 10/15/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import UIKit
import Photos
import Firebase

class SelfieCollectionManager {
    
    lazy var selfieDataString = "SELFIE"
    var images = [PHAsset]()
    let options = VisionFaceDetectorOptions()
    lazy var vision = Vision.vision()
    let myGroup = DispatchGroup()
    
    init(){
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all
        options.minFaceSize = CGFloat(0.1)
    }
    
    func getPHAsset(fetchLimit:Int, startDate:NSDate, endDate:NSDate) -> PHFetchResult<PHAsset>{
        let options = PHFetchOptions()
        //Sort in descending order such that the first result will be the latest
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.includeAllBurstAssets = false
        options.includeAssetSourceTypes = [PHAssetSourceType.typeUserLibrary]
        options.fetchLimit = fetchLimit
        options.predicate = NSPredicate(format: "creationDate > %@ AND creationDate < %@", startDate, endDate)
        
        return  PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
    }
    

    func collect(completion: @escaping (_ success: Bool) -> Void){
        let uploadTimeDate = Date(timeIntervalSince1970: Double(AppDelegate.lastSelfieExtraction / 1000))
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        //let currentDateString = dateFormatter.string(from: Date())
        //let uploadDateString = dateFormatter.string(from: uploadTimeDate)
        
        /*
        if currentDateString == uploadDateString {
            //print("Selfie collection stopped, already occured today.")
            return
        }
        */
 
        
        let assets = getPHAsset(fetchLimit: 10, startDate: uploadTimeDate as NSDate, endDate: Date() as NSDate)
        if assets.count == 0{
            completion(false)
            return
        }

        var lastDateObject: Date?
        let anotherDispatchGroup = DispatchGroup()
        DispatchQueue.global().async{
            anotherDispatchGroup.enter()
            var i = 1
            assets.enumerateObjects({(object,count,stop) in
                //Only add photos with valid dates.
                guard let tempImage = self.getAssetImage(asset: object) else {
                    NSLog("image returned nil.")
                    i += 1
                    return
                }
                
                lastDateObject = object.creationDate
                let epoch = Int64(object.creationDate!.timeIntervalSince1970 * 1000)
                self.myGroup.enter()
                let queue = DispatchQueue(label: "detectQueue")
                queue.async {
                    self.detect(photo: tempImage, epoch: epoch)
                }
                self.myGroup.wait()
                //print("count: \(i)")
                if AppDelegate.memoryWarning{
                    stop.pointee = true
                    anotherDispatchGroup.leave()
                }
                if assets.count == i {
                    //TODO find bug here
                    anotherDispatchGroup.leave()
                }
                i += 1
                
            })
            anotherDispatchGroup.notify(queue: .global(), execute: {
                //print("notify")
                let lastEpoch = Int64(lastDateObject!.timeIntervalSince1970 * 1000) + 1000
                EarsService.shared.setLastSelfieExtractionTime(newValue: lastEpoch)
                AppDelegate.lastSelfieExtraction = lastEpoch
                completion(true)
            })
        }
    }
    
    func cropImage(image: UIImage, toRect: CGRect, imageOrient: UIImage.Orientation) -> UIImage? {
        // Cropping is available through CGGraphics
        //print("crop called")
        let imgScale = image.scale
        
        
        let cgImage :CGImage! = image.cgImage
        let croppedCGImage: CGImage! = cgImage.cropping(to: toRect)
        let coreImage = CIImage(cgImage: croppedCGImage!)
        
        let ciContext =  coreContextFor(forceSoftware: true)
        let filteredImageRef = ciContext.createCGImage(coreImage, from: coreImage.extent)
        let finalImage = UIImage(cgImage:filteredImageRef!, scale:imgScale, orientation:imageOrient)
        
        return finalImage
    }
    
    func getAssetImage(asset: PHAsset) -> UIImage? {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var rawImage: UIImage? = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            rawImage = result
            //self.myGroup.leave()
        })
        return rawImage
    }
    
    
    func coreContextFor(forceSoftware force : Bool) -> CIContext {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let options : [CIContextOption:Any] = [
            CIContextOption.workingColorSpace: colorSpace,
            CIContextOption.outputColorSpace : colorSpace,
            CIContextOption.useSoftwareRenderer : NSNumber(value: force),
            CIContextOption.priorityRequestLow : NSNumber(value: force)
        ]
        
        return CIContext(options: options)
    }

    
    func detect(photo: UIImage, epoch: Int64) {
        //print("run detect")
        let currentOrientation = photo.imageOrientation
        let newImage = UIImage(cgImage: photo.cgImage!, scale: photo.scale, orientation: .up)
        
        let faceDetector = self.vision.faceDetector(options: self.options)
        let visionImage = VisionImage(image: newImage)
        


        var i = 1
        faceDetector.process(visionImage) { (faces, error) in
            //2
            guard error == nil, let faces = faces, !faces.isEmpty else {
                //print("No Face Detected")
                self.myGroup.leave()
                return
            }
            //3
            //print("I see \(faces.count) face(s).\n\n")
            
            for face in faces {
        
            
                //print("   Face was detected.")
                //print("     found bounds are \(face.frame)")
                
                // Calculate the actual position and size of the rectangle in the image view
                
                let crop = self.cropImage(image: newImage, toRect: face.frame, imageOrient: currentOrientation)
                let selfie_data = crop!.jpegData(compressionQuality: 1.0)
                
                let dataStorage = DataStorage()
                dataStorage.writeEncryptedImage(dataType: self.selfieDataString, data: selfie_data!, epoch: epoch, count : i)
                //print(i)
                if i == faces.count{
                    self.myGroup.leave()
                }
                i += 1
            }

        }
    }
    
    deinit {
        //NSLog("SelfieManager Deinit invoked.")
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            NSLog("Image error : \(error)")
        } else {
            NSLog("Error obtaining image error.. sorry.")
        }
    }

    
    
    
    
}
