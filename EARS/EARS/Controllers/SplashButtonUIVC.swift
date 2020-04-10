//
//  SplashButtonUIViewController.swift
//  EARS
//
//  Created by Wyatt Reed on 7/3/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale


class SplashButtonUIVC: UIViewController {
    var strings:[String] = []
    @IBOutlet weak var bulletLabel: UILabel!
    @IBOutlet weak var titleTextView: UITextView!
    
    @IBOutlet weak var bodyText: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        titleTextView.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)

        drawUnorderedList()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func drawUnorderedList() {
        // create our NSTextAttachment
        let bulletImage = NSTextAttachment()
        bulletImage.image = UIImage(named: "check")
        let image1String = NSAttributedString(attachment: bulletImage)
        
        let bullet0 = "bullet0".localized()
        let bullet1 = "bullet1".localized()
        let bullet2 = "bullet2".localized()
        let bullet3 = "bullet3".localized()
        
        strings = [bullet0, bullet1, bullet2, bullet3]
        
        let attributesDictionary = [NSAttributedString.Key.font : bulletLabel.font]
        let fullAttributedString = NSMutableAttributedString(string: "", attributes: attributesDictionary as Any as? [NSAttributedString.Key : Any])
        
        for string: String in strings {
            
            let formattedString = NSMutableAttributedString(string: "")
            formattedString.append(image1String)
            formattedString.append(NSAttributedString(string: " \(string)\n\n"))
            let attributedString: NSMutableAttributedString = formattedString
            
            let paragraphStyle = createParagraphAttribute()
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSMakeRange(0, attributedString.length))
            
            fullAttributedString.append(attributedString)
        }
        
        bulletLabel.attributedText = fullAttributedString
    }
    
    private func createParagraphAttribute() ->NSParagraphStyle
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 15, options: Dictionary<NSTextTab.OptionKey, Any>())]
        paragraphStyle.defaultTabInterval = 20
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 20
        
        return paragraphStyle
    }
    

}
