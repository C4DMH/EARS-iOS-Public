//
//  SensorsVC.swift
//  EARS
//
//  Created by Wyatt Reed on 2/8/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale

class SensorsVC: UIViewController {
    
    
    @IBOutlet weak var bodyText: UITextView!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //Create navigation bar instance
        placeNavigationBar()
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
       
    
    }
    override func viewWillAppear(_ animated : Bool){
        super.viewWillAppear(animated)
        
        //updateNavigationBarAppearance()
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    func placeNavigationBar(){
        
        //Create navigation item for presenting content
        let item = UINavigationItem()
        let label = UILabel()
        label.text = "Active Sensors".localized()
        label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        item.titleView = label
        
        let navigationBar = UINavigationBar()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = #colorLiteral(red: 0.03430948406, green: 0.1574182212, blue: 0.3626363277, alpha: 1)
        
        //Add it to viewcontroller's view and set it's constraints
        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        //Set navigation item we created to new navigation bar to display it
        navigationBar.items = [item]
        createBackBarButton(forNavigationItem: item)
        navigationBar.delegate = self
    }
    @IBAction func backBarButtonTapped(_ sender: AnyObject) {
        //delegate?.handShake(controller: self, text: "back")
        self.dismiss(animated: true, completion: nil)
        AppDelegate.homeInstance.sensorsVC = nil
    }
    
    func createBackBarButton(forNavigationItem navigationItem:UINavigationItem){
        var backButtonImage = UIImage(named: "backLeft")
        backButtonImage = backButtonImage?.imageRotatedByDegrees(degrees: -90, flip: false)
        backButtonImage = backButtonImage?.withRenderingMode(.alwaysTemplate)

        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: backButtonImage!.size.width, height: backButtonImage!.size.height))
        backButton.tintColor = UIColor.white
        //          backButton.backgroundColor = UIColor.red

        backButton.contentEdgeInsets = UIEdgeInsets(top: backButtonImage!.size.height / 2, left: backButtonImage!.size.width , bottom: backButtonImage!.size.height / 2 , right: backButtonImage!.size.width * 2)
        backButton.setImage(backButtonImage!, for: .normal)
        backButton.addTarget(self, action: #selector(SensorsVC.backBarButtonTapped), for: .touchUpInside)
        let backBarButton = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItems = [backBarButton]
    }
    
    deinit{
        //NSLog("SensorsVC deinit invoked.")
    }

}
extension SensorsVC:UINavigationBarDelegate{
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

// Rotating UIImage in Swift
// https://stackoverflow.com/a/29753437/7507949
extension UIImage {
    // Why save a rotated image asset when you can rotate it every time...
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        /*
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(Double.pi))
        }
        */
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(Double.pi)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees))
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)

        
        //   // Rotate the image context
        bitmap?.rotate(by: degreesToRadians(degrees))
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        //CGContextScaleCTM(bitmap!, yFlip, -1.0)
        bitmap?.scaleBy(x: yFlip, y: -1.0)
        bitmap?.draw( cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2,width: size.width,height: size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
