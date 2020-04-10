//
//  SplashZeroVC.swift
//  EARS
//
//  Created by Wyatt Reed on 1/29/19.
//  Copyright © 2019 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale


class SplashZeroVC: UIViewController {

    @IBOutlet weak var bunnyImage: UIImageView!
    
    @IBOutlet weak var bodyText: UITextView!
    
    @IBOutlet weak var titleTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        titleTextView.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
