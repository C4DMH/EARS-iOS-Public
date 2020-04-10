//
//  StepCompleteInstallVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/16/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale


protocol StepCompleteInstallVCDelegate{
    func handShake(controller:StepCompleteInstallVC,text:String)
}

class StepCompleteInstallVC: UIViewController {
    
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var completeButton: roundedButton!
    
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var selfiePreview: CircleImageView!
    var delegate:StepCompleteInstallVCDelegate? = nil
    var selfie: UIImage? = nil
    var rotated_selfie: UIImage? = nil
    var selfieBounds: CGRect!

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        retakeButton.titleLabel?.textAlignment = .center
        selfiePreview.image = selfie
        //selfiePreview.updateImageRadius()
        retakeButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        completeButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)
        
        rotated_selfie = imageRotatedByDegrees(oldImage: selfie!, deg: 90)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func retakePhoto(_ sender: AnyObject) {
        delegate?.handShake(controller: self, text: "retake")
    }
    
    @IBAction func uploadPhoto(_ sender: AnyObject) {
        let store = DataStorage()
        let selfie_data = rotated_selfie!.jpegData(compressionQuality: 1.0)
        let queue = DispatchQueue(label: "SerialQueuePhoto")
        
        queue.async {
            store.writeEncryptedImage(dataType: "SELFIE", data: selfie_data!, epoch: Int64(Date().timeIntervalSince1970 * 1000), count: 0)
        }
        
        queue.async {
            store.uploadData(dataType: "SELFIE")
        }
        delegate?.handShake(controller: self, text: "done")
        //self.unloadImages()
        
    }
    func unloadImages() {
        rotated_selfie = nil
        selfie = nil
        delegate = nil
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    deinit {
        //print("StepCompleteInstall deinit invoked.")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
