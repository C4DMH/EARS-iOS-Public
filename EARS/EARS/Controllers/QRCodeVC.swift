//
//  QRCodeVC.swift
//  EARS
//
//  Created by Wyatt Reed on 4/2/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import Foundation


protocol QRCodeVCDelegate{
    func handShake(controller:QRCodeVC,text:String)
}

struct Card {
    var code: String
    var imageName: String
    var title: String
    var description: String
}

class QRCodeVC: UIViewController {

    @IBOutlet weak var videoPreview: UIView!
    
    @IBOutlet weak var boxImage: UIImageView!
    
    
    private var videoLayer: CALayer!
    
    var delegate: QRCodeVCDelegate? = nil
    
    var codeReader: QRCodeManager!
    
    var didFindCard: ((Card) -> Void)?
    var didReadUnknownCode: ((String) -> Void)?
    
    
    override func viewDidLoad() {
        codeReader = QRCodeManager()
        videoLayer = codeReader.videoPreview
        videoPreview.layer.addSublayer(videoLayer)
        placeNavigationBar()
        view.bringSubviewToFront(boxImage)
    }
    
    func placeNavigationBar(){
        
        //Create navigation item for presenting content
        let item = UINavigationItem()
        
        //Create an imageview to display image
        let label = UILabel()
        label.text = "Scan QR Code.".localized()
        label.textColor = #colorLiteral(red: 0.03430948406, green: 0.1574182212, blue: 0.3626363277, alpha: 1)
        
        //Set imageview to newly created navigation item
        item.titleView = label
        
        let navigationBar = UINavigationBar()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = UIColor.white
        
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
    func createBackBarButton(forNavigationItem navigationItem:UINavigationItem){
        var backButtonImage = UIImage(named: "backLeft")
        backButtonImage = backButtonImage?.withRenderingMode(.alwaysTemplate)
        
        
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: backButtonImage!.size.width, height: backButtonImage!.size.height))
        backButton.tintColor = #colorLiteral(red: 0.03430948406, green: 0.1574182212, blue: 0.3626363277, alpha: 1)
        
        backButton.contentEdgeInsets = UIEdgeInsets(top: backButtonImage!.size.height / 2, left: backButtonImage!.size.width , bottom: backButtonImage!.size.height / 2 , right: backButtonImage!.size.width * 2)
        backButton.setImage(backButtonImage!, for: .normal)
        backButton.addTarget(self, action: #selector(self.backBarButtonTapped), for: .touchUpInside)
        let backBarButton = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItems = [backBarButton]
    }
    @IBAction func backBarButtonTapped(_ sender: AnyObject) {
        //delegate?.handShake(controller: self, text: "back")
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoLayer.frame = videoPreview.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        codeReader.startReading { [weak self] (code) in
            //print("\(code)")
            self!.delegate?.handShake(controller: self!, text: code)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        codeReader.stopReading()
    }
    deinit {
        //print("QRCode deinit invoked.")
    }
    
}

extension QRCodeVC:UINavigationBarDelegate{
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
