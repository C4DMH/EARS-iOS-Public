//
//  PageViewController.swift
//  EARS
//
//  Created by Wyatt Reed on 7/2/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import ResearchKit
import WebKit


class PageViewController: UIPageViewController, ORKTaskViewControllerDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource, StudySelectVCDelegate {
    
    //three dots
    var pageControl : UIPageControl!
    var continueButton : UIButton!
    
    var code = ""
    var study = ""
    var studyCodeCreationDate = ""
    
    override func viewDidLoad() {
        //If a user has selected a study previously but quit the app during setup, clear the studyName here.
        if AppDelegate.study != nil{
            EarsService.shared.setStudyName(newValue: "")
        }
        self.delegate = self
        configurePageControl()
        super.viewDidLoad()
        self.dataSource = self
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    public weak var ConsentTask: ORKOrderedTask? {
        
        let Document = ORKConsentDocument()
        Document.title = "ToSTitle".localized()
        
        let sectionTypes: [ORKConsentSectionType] = [
            .overview,
            .dataGathering,
            .privacy,
            //.dataUse,
            //.timeCommitment,
            .studySurvey,
            //.studyTasks,
            .withdrawing,
            .custom
        ]
        
        let sectionStrings: [ORKConsentSectionType:String] = [
            .overview:"overview",
            .dataGathering:"dataGathering",
            .privacy:"privacy",
            //.dataUse:"dataUse",
            //.timeCommitment:"timeCommitment",
            .studySurvey:"studySurvey",
            //"studyTasks",
            .withdrawing:"withdrawing",
            .custom:"gettingHelp"
        
        ]
        
        let consentSections: [ORKConsentSection] = sectionTypes.map { contentSectionType in
            
            let consentSection = ORKConsentSection(type: contentSectionType)
            let consentString : String = sectionStrings[contentSectionType]!
            
            consentSection.summary = "\(consentString)Summary".localized()

            consentSection.content = "\(consentString)Content".localized()
            if consentString == "gettingHelp"{
                consentSection.title = "\(consentString)Title".localized()
                consentSection.customImage = UIImage(named: "exclamation")
            }
            if consentString == "overview"{
                consentSection.title = "\(consentString)Title".localized()
            }
            return consentSection
        }
        
        
        Document.sections = consentSections
        Document.addSignature(ORKConsentSignature(forPersonWithTitle: nil, dateFormatString: nil, identifier: "UserSignature"))
        
        var steps = [ORKStep]()
        
        //Visual Consent
        let visualConsentStep = ORKVisualConsentStep(identifier: "VisualConsent", document: Document)
        steps += [visualConsentStep]
        
        //Signature
        //let signature = Document.signatures!.first! as ORKConsentSignature
        let reviewConsentStep = ORKConsentReviewStep(identifier: "Review", signature: nil, in: Document)
        reviewConsentStep.text = "reviewConsentStepText".localized()
        reviewConsentStep.reasonForConsent = "reviewConsentStepReasonForConsent".localized()
        
        steps += [reviewConsentStep]
        
        //Completion
        let completionStep = ORKCompletionStep(identifier: "CompletionStep")
        completionStep.title = "completionStepTitle".localized()
        completionStep.text = "completionStepText".localized()
        steps += [completionStep]
        
        return ORKOrderedTask(identifier: "ConsentTask", steps: steps)
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        taskViewController.dismiss(animated: true, completion: nil)
        
        
        if reason == ORKTaskViewControllerFinishReason.completed{
            var stepResult = taskViewController.result.stepResult(forStepIdentifier: "Review")?.results
            let tempResult: ORKResult = (stepResult?.removeFirst())!
            let consented = tempResult.value(forKeyPath: "consented") as! Int
            //If user has accepted the consent after completion
            let studyVariablesPrepared = AppDelegate.studyDict.count > 0
            if consented == 1 && studyVariablesPrepared{
                AppDelegate.study?.setVariables(studyName: self.study)
                verifyStudyCode(code: self.code, study: self.study, studyCodeCreationDate: self.studyCodeCreationDate)
            }else{
                disableBackgroundBlur()
                EarsService.shared.setStudyName(newValue: "")
                AppDelegate.study = nil
                
            }

        }else{
            disableBackgroundBlur()
            EarsService.shared.setStudyName(newValue: "")
            AppDelegate.study = nil
        }
        
    }

    var currentPage = 0
    lazy var orderedViewControllers: [UIViewController] = {
        return [self.newVc(viewController: "splashOne"),
                self.newVc(viewController: "splashTwo"),
                self.newVc(viewController: "splashThree")]
    }()
    
    func verifyStudyCode(code: String, study: String, studyCodeCreationDate: String){
        //Create deadlock before checking if request was successful.
        let group = DispatchGroup()
        group.enter()
        
        var studyClaimSuccess = false
        DispatchQueue.main.async{
            //params: code, study, studyCodeCreationDate, deviceID
            var request = URLRequest(url: NSURL(string: "\(studyCodeVerificationURL)?code=\(code)&study=\(study)&studyCodeCreationDate=\(studyCodeCreationDate)&OS=iOS&deviceID=\(AppDelegate.device_id)")! as URL)
            request.httpMethod = "POST"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    NSLog("error=\(String(describing: error))")
                    group.leave()
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    NSLog("statusCode should be 200, but is \(httpStatus.statusCode)")
                    //print("response = \(response!)")

                }
                
                var responseString = String(data: data, encoding: .utf8)
                //print("responseString = \(responseString)")
                responseString = "[\(responseString!)]"
                let data2 = responseString!.data(using: .utf8)!
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data2, options : .allowFragments) as? [Dictionary<String,Any>]
                    {
                        // use the json here
                        if jsonArray[0].keys.contains("success"){
                            studyClaimSuccess = jsonArray[0]["success"] as! Bool
                            //print(studyClaimSuccess)
                        }
                    } else {
                        //print("bad json")
                    }
                } catch let error as NSError {
                    NSLog("error\(error)")
                }
                group.leave()
                
            }
            task.resume()
        }

        group.notify(queue: .main) {
            if studyClaimSuccess{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                EarsService.shared.setConsentComplete(newValue: true)
                //Continue to next view controller
                appDelegate.changeRootViewController(with: "stepZero")
            }else{
                //This ideally occurs when the code has been claimed somehow while the user is still completing the consent step.
                //Or possibly if the user lost internet, in that case they have to try again.
                self.disableBackgroundBlur()
                EarsService.shared.setStudyName(newValue: "")
                AppDelegate.study = nil
            }
        }
        
    }
    
    
    func configurePageControl() {
        // The total number of pages that are available is based on the length of orderedViewControllers.
        pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 90,width: UIScreen.main.bounds.width,height: 50))
        self.pageControl.numberOfPages = orderedViewControllers.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.white
        self.pageControl.pageIndicatorTintColor = UIColor.black
        self.pageControl.currentPageIndicatorTintColor = UIColor.white
        self.pageControl.isUserInteractionEnabled = false
        self.view.addSubview(pageControl)
        self.pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        // button
        continueButton = UIButton()
        continueButton.setTitle("Continue".localized(), for: .normal)
        continueButton.layer.cornerRadius = 15
        continueButton.clipsToBounds = true
        continueButton.backgroundColor = UIColor(displayP3Red: 2/255, green: 110/255, blue: 196, alpha: 1)
        continueButton.setTitleColor(UIColor.white, for: .normal)
        continueButton.frame = CGRect(x: 0,y: UIScreen.main.bounds.maxY - 50,width: UIScreen.main.bounds.width * 0.98,height: 50)
        continueButton.addTarget(self, action: #selector(self.buttonClicked), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.view.addSubview(continueButton)
        
        let horizontalConstraint = NSLayoutConstraint(item: continueButton, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let horizontalConstrainttwo = NSLayoutConstraint(item: pageControl, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: continueButton, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: UIScreen.main.bounds.width * 0.98)
        let heightConstraint = NSLayoutConstraint(item: continueButton, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 50)
        self.view.addConstraints([horizontalConstraint,horizontalConstrainttwo, widthConstraint, heightConstraint])
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalToSystemSpacingBelow: continueButton.topAnchor, multiplier: 1.0),
                guide.bottomAnchor.constraint(equalToSystemSpacingBelow: continueButton.bottomAnchor, multiplier: 1.0)
                ])
        }
        
    }
    
    /// When linked button is clicked, this function will increment the current pageview controller index.
    @objc func buttonClicked() {
        let nextIndex = currentPage + 1
        
        if orderedViewControllers.count == nextIndex {
            
            let vcsz:StudySelectVC = (storyboard?.instantiateViewController(withIdentifier: "studySelect") as? StudySelectVC)!
            vcsz.delegate = self
            vcsz.modalTransitionStyle = .crossDissolve
            present(vcsz, animated: true, completion: nil)
        
        }else{
            self.pageControl.currentPage = nextIndex
            setViewControllers([orderedViewControllers[nextIndex]], direction: .forward, animated: true, completion: nil)
            currentPage = nextIndex
        }
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl.currentPage = orderedViewControllers.firstIndex(of: pageContentViewController)!
        currentPage = orderedViewControllers.firstIndex(of: pageContentViewController)!
    }
    
    func newVc(viewController: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewController)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }

        let previousIndex = viewControllerIndex - 1
        
        
        guard previousIndex >= 0 else {
            //return orderedViewControllers.last
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        
        let nextIndex = viewControllerIndex + 1
        
        guard orderedViewControllers.count != nextIndex else {
            //return orderedViewControllers.first
            return nil
        }
        
        guard orderedViewControllers.count > nextIndex else {
            return nil
        }
        
        
        return orderedViewControllers[nextIndex]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handShake(controller:StudySelectVC,text:String, studyVars:[String]){
        //NSLog("recieved")
        if (text == "back"){
            controller.dismiss(animated: true, completion: nil)
        }else{
            let cap = text.uppercased()
            self.code = studyVars[0]
            self.study = studyVars[1]
            self.studyCodeCreationDate = studyVars[2]
            
            //print(cap)
            EarsService.shared.setStudyName(newValue: text)
            //async
            AppDelegate.study = StudyManager()
            AppDelegate.study?.pullStudyVariables(study: text)
            UserDefaults.standard.set(cap, forKey: "study_pref")
            
            enableBackgroundBlur()
            controller.dismiss(animated: true, completion: nil)
            let taskViewController = ORKTaskViewController(task: ConsentTask, taskRun: nil)
            taskViewController.delegate = self
            taskViewController.modalPresentationStyle = .fullScreen
            present(taskViewController, animated: true, completion: nil)
        }
    }
    static var blurEffectView:UIVisualEffectView?
    
    func enableBackgroundBlur(){
        if !UIAccessibility.isReduceTransparencyEnabled {
            view.backgroundColor = .clear
            
            let blurEffect = UIBlurEffect(style: .regular)
            PageViewController.blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            PageViewController.blurEffectView?.frame = CGRect(origin: CGPoint(x: 0, y: -50), size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 50 ))
            PageViewController.blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.clipsToBounds = false
            view.addSubview(PageViewController.blurEffectView!)
        } else {
            //self.view.backgroundColor = UIColor(white: 1, alpha: 0.5)
            //self.view.isOpaque = true
        }
    }
    func disableBackgroundBlur(){
        if !UIAccessibility.isReduceTransparencyEnabled {
            //NSLog("disableBackgroundBlur")
            if(PageViewController.blurEffectView != nil){
                PageViewController.blurEffectView?.removeFromSuperview()
                PageViewController.blurEffectView = nil
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    deinit {
        //NSLog("PageViewController deinit invoked.")
    }
    
    
    

}
