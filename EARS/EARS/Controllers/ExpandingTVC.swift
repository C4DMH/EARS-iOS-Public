//
//  ExpandingTVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/12/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit

class ExpandingTVC: UITableViewController {
    
    @IBOutlet weak var needToTalkText: UITextView!
    private var cellOneExpanded: Bool = false
    private var cellTwoExpanded: Bool = false
    private var cellThreeExpanded: Bool = false
    
    @IBOutlet weak var emaBadge: UIImageView!
    @IBOutlet weak var badgeFill: UIImageView!
    @IBOutlet weak var moodCheckinLabel: UILocalizedLabel!
    

    override func viewDidLoad() {

        super.viewDidLoad()
        if AppDelegate.homeInstance != nil{
            AppDelegate.homeInstance.setExpandingTVC(view: self)
        }else{
            DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(1), execute:{
                if AppDelegate.homeInstance != nil{
                    AppDelegate.homeInstance.setExpandingTVC(view: self)
                }else{
                    NSLog("unable to locate homeInstance")
                }
            })
        }
        populateCellTextViews()
    
    }
    private func populateCellTextViews(){
        /**
         * Method name: populateCellTextViews -> Void
         * Description: Replaces the text of specific textviews for cells in the table. Generates a URL to the appstore in the range of a localized description string for the "Need to Talk?" cell.
         */
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .link: NSURL(string: "itms-apps://itunes.apple.com/app/id921814681")!,
            .foregroundColor: UIColor.blue
        ]
        let descriptionOne = "needToTalkDescription".localized()
        
        let attributedString = NSMutableAttributedString(string: descriptionOne)
        let linkText = "needToTalkLinkText".localized()
        let substringRange = descriptionOne.range(of: linkText)
        attributedString.setAttributes(linkAttributes, range: NSRange(substringRange!, in: descriptionOne))
        needToTalkText.attributedText = attributedString
        needToTalkText.linkTextAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.9562190175, green: 0.9221588969, blue: 0.2882983088, alpha: 1)]
        needToTalkText.textColor = UIColor.white
        
        tableView.tableFooterView = UIView()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        return 3
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO : remove this embarassment of a switch
        switch indexPath.row {
        case 0:
            if cellOneExpanded {
                cellOneExpanded = false
            }else{
                cellOneExpanded = true
                cellTwoExpanded = false
                cellThreeExpanded = false
            }
        case 1:
            //print("\(AppDelegate.study?.study)")
            if (AppDelegate.study?.includedSensors["ema"])! && AppDelegate.study?.study.lowercased() != "maps"{
                AppDelegate.homeInstance.removedOldEMAs{ (success) -> Void in
                    //AppDelegate.homeInstance.chainEMAs()
                    
                    //test cases
                    AppDelegate.homeInstance.dukeInstance?.startDukeSurvey(ident: "test")
                }
                cellTwoExpanded = false
                cellOneExpanded = false
                cellThreeExpanded = false
            }else{
                if cellTwoExpanded {
                    cellTwoExpanded = false
                }else{
                    cellTwoExpanded = true
                    cellOneExpanded = false
                    cellThreeExpanded = false
                }
            }

        case 2:
            weak var vc = storyboard?.instantiateViewController(withIdentifier: "SensorsVC") as? SensorsVC
            AppDelegate.homeInstance.sensorsVC = vc
            vc!.modalPresentationStyle = .overCurrentContext
            //presentDetail(vc!)
            
            present(vc!,animated: true, completion: nil)
            cellThreeExpanded = false
            cellOneExpanded = false
            cellTwoExpanded = false
        default:
            cellThreeExpanded = false
            cellOneExpanded = false
            cellTwoExpanded = false
        }

        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            if cellOneExpanded {
                return 135
            }else{
                return 40
            }
        case 1:
            if cellTwoExpanded {
                return 75
            }else{
                return 40
            }
        case 2:
            if cellThreeExpanded {
                return 75
            }else{
                return 40
            }
        default:
            return 50
        }

    }
    func updateBadge(number: Int){
        switch number {
        case 0:
            badgeFill.isHidden = true
            emaBadge.isHidden = true
            moodCheckinLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.8470588235, blue: 0.8470588235, alpha: 0.5989783654)
            if #available(iOS 13.0, *) {
                emaBadge.image = UIImage(systemName: "largecircle.fill.circle")
            } else {
                // Fallback on earlier versions
            }
        case 1:
            if #available(iOS 13.0, *) {
                emaBadge.image = UIImage(systemName: "1.circle.fill")
            } else {
                // Fallback on earlier versions
            }
            moodCheckinLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.8470588235, blue: 0.8470588235, alpha: 1)
            emaBadge.isHidden = false
            badgeFill.isHidden = false
        case 2:
            if #available(iOS 13.0, *) {
                emaBadge.image = UIImage(systemName: "2.circle.fill")
            } else {
                // Fallback on earlier versions
            }
            moodCheckinLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.8470588235, blue: 0.8470588235, alpha: 1)
            emaBadge.isHidden = false
            badgeFill.isHidden = false
        case 3:
            if #available(iOS 13.0, *) {
                emaBadge.image = UIImage(systemName: "3.circle.fill")
            } else {
                // Fallback on earlier versions
            }
            moodCheckinLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.8470588235, blue: 0.8470588235, alpha: 1)
            emaBadge.isHidden = false
            badgeFill.isHidden = false
        default:
            if #available(iOS 13.0, *) {
                emaBadge.image = UIImage(systemName: "largecircle.fill.circle")
            } else {
                // Fallback on earlier versions
            }
            moodCheckinLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.8470588235, blue: 0.8470588235, alpha: 1)
            emaBadge.isHidden = false
            badgeFill.isHidden = false
        }
    }

}
