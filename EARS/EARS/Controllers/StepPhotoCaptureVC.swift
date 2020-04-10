//
//  StepPhotoCaptureVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/16/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import Photos
import CoreImage
import AMXFontAutoScale


class StepPhotoCaptureVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, StepCompleteInstallVCDelegate {
    @IBOutlet weak var takePictureButton: roundedButton!
    
    
    @IBOutlet weak var bodyText: UITextView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    
    var faceBounds: CGRect!
    
    var imagePicker: UIImagePickerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)

        imagePicker = UIImagePickerController()
        imagePicker!.delegate = self
        takePictureButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        
        //Prevent accidental button interaction before permissions have been presented.
        takePictureButton.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.takePictureButton.isEnabled = true
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func takePhoto(_ sender: AnyObject) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            weak var vc = storyboard?.instantiateViewController(withIdentifier: "stepCompleteInstall") as? StepCompleteInstallVC
            vc!.delegate = self
            present(vc!, animated: true, completion: nil)
            return
        }
        
        if (PHPhotoLibrary.authorizationStatus() == .notDetermined) {
            
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({status in
                
                if (status == .authorized) {
                    //NSLog("photo access authorized")
                }else{
                    //NSLog("photo access not authorized")
                }
            })
        }
        
        imagePicker!.allowsEditing = false
        imagePicker!.sourceType = .camera
        
        //its a selfie
        imagePicker!.cameraDevice = .front
        
        present(imagePicker!, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        var photo = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage

        imagePicker!.dismiss(animated: true, completion: nil)
        //let faceDetect = self.detect(selfie: photo!)
        if self.detect(selfie: photo!){
            weak var vc = storyboard?.instantiateViewController(withIdentifier: "stepCompleteInstall") as? StepCompleteInstallVC
            vc!.delegate = self
            
            vc!.selfie = cropImage(image: (info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage)!, toRect: faceBounds)
            vc!.selfieBounds = faceBounds
            present(vc!, animated: true, completion: nil)
            //vc = nil
        }
        photo = nil
        
    }
    func cropImage(image: UIImage, toRect: CGRect) -> UIImage? {
        // Cropping is available through CGGraphics
        let imgOrientation = image.imageOrientation
        let imgScale = image.scale
        
        
        var cgImage :CGImage! = image.cgImage
        var croppedCGImage: CGImage! = cgImage.cropping(to: toRect)
        let coreImage = CIImage(cgImage: croppedCGImage!)
        
        let ciContext = CIContext(options: nil)
        let filteredImageRef = ciContext.createCGImage(coreImage, from: coreImage.extent)
        
        //let finalImage = UIImage(cgImage:filteredImageRef!, scale:imgScale, orientation:imgOrientation)
        
        cgImage = nil
        croppedCGImage = nil
        
        return UIImage(cgImage:filteredImageRef!, scale:imgScale, orientation:imgOrientation)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func detect(selfie: UIImage) -> Bool {
        let imageOptions =  NSDictionary(object: NSNumber(value: 3) as NSNumber, forKey: CIDetectorImageOrientation as NSString)
        let personciImage = CIImage(cgImage: selfie.cgImage!)
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage, options: imageOptions as? [String : AnyObject])
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
            //CGAffineTransformTranslate(transform, 0, -ciImageSize.height)
        if let face = faces?.first as? CIFaceFeature {
            
            //print("found bounds are \(face.bounds)")
            // Apply the transform to convert the coordinates
            let faceViewBounds = face.bounds.applying(transform)
            
            // Calculate the actual position and size of the rectangle in the image view
            faceBounds = faceViewBounds
            //print("transformed bounds are \(faceViewBounds)")
            /*
            if face.hasSmile {
                print("face is smiling");
            }
            
            if face.hasLeftEyePosition {
                print("Left eye bounds are \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition {
                print("Right eye bounds are \(face.rightEyePosition)")
            }
            */
            return true
            
        } else {
            let alert = UIAlertController(title: "No Face!".localized(), message: "No face was detected".localized(), preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return false
        }
    }
    
    func handShake(controller: StepCompleteInstallVC, text: String) {
        //NSLog("recieved")
        if (text == "retake"){
            controller.dismiss(animated: true, completion: nil)
            
            takePictureButton.sendActions(for: .touchUpInside)
        }
        if (text == "done"){
            controller.dismiss(animated: true, completion: nil)
            
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.changeRootViewController(with: "acknowledgement")
            
        }
    }
    
    deinit{
        //print("StepPhotoCaptureVC deinit invoked.")
        //imagePicker = nil
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
