//
//  StudySelectVC.swift
//  EARS
//
//  Created by Wyatt Reed on 12/6/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AMXFontAutoScale

protocol StudySelectVCDelegate{
    func handShake(controller:StudySelectVC,text:String, studyVars:[String])
}

class StudySelectVC: UIViewController, UITextFieldDelegate, QRCodeVCDelegate {
    
    @IBOutlet weak var titleTextView: UITextView!
    
    @IBOutlet weak var bodyText: UITextView!
    
    var studyManager: StudyManager?
    
    var delegate:StudySelectVCDelegate? = nil
    
    @IBOutlet weak var studyCodeTextField: UITextField!
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backButton: roundedButton!
    @IBOutlet weak var submit: roundedButton!
    @IBOutlet weak var qrButton: UIButton!
    
    
    var spinner: UIActivityIndicatorView!
    var shake = true
    
    var originalHeight:CGFloat?
    var topOriginalHeight:CGFloat?
    
    var code = ""
    var study = ""
    var studyCodeCreationDate = ""
    var studyCodeClaimed = true
    var errorResponse = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bodyText.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)
        titleTextView.amx_autoScaleFont(forReferenceScreenSize: .size4Inch)

        
        spinner = UIActivityIndicatorView()
        
        self.studyCodeTextField.delegate = self
        studyCodeTextField.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        studyCodeTextField.autocorrectionType = .no
        studyCodeTextField.autocapitalizationType = .allCharacters
        self.studyCodeTextField.setBottomBorderOnlyWith(color: #colorLiteral(red: 0.03430948406, green: 0.1574182212, blue: 0.3626363277, alpha: 1))
        originalHeight = keyboardHeightLayoutConstraint?.constant
        topOriginalHeight = topLayoutConstraint?.constant
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        submit.addTarget(self, action: #selector(validateStudyCode), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        qrButton.addTarget(self, action: #selector(qrCode), for: .touchUpInside)
        qrButton.isHidden = false
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        addActivityIndicator()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    var blurEffectView: UIVisualEffectView?
    func addActivityIndicator() {
        spinner.hidesWhenStopped = true
        spinner.style = UIActivityIndicatorView.Style.gray
        spinner.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        spinner.transform = CGAffineTransform(scaleX: 2, y: 2)
        spinner.center = self.view.center
        blurEffectView = UIVisualEffectView(effect: nil)
        blurEffectView!.frame = view.bounds
        blurEffectView!.alpha = 0.5
        blurEffectView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView!)
        blurEffectView?.isHidden = true
        view.addSubview(spinner)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        //or
        //self.view.endEditing(true)
        return true
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let previousText:NSString = textField.text! as NSString
        let updatedText = previousText.replacingCharacters(in: range, with: string)
        
        // Detect backspace Event in UITextField
        // https://stackoverflow.com/questions/29504304/detect-backspace-event-in-uitextfield/29505548
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")

        if !string.replacingOccurrences(of: " ", with: "").isAlphanumeric() && isBackSpace != -92{
            return false
        }
        
        if(updatedText.count) > 19{
            return false
        }

        let text = textField.text?.uppercased() ?? ""
        
        if string.count == 0 {
            textField.text = String(text.dropLast()).chunkFormatted()
        }
        else {
            let newText = String((text + string.uppercased())
                .filter({ $0 != " " }).prefix(16))
            textField.text = newText.chunkFormatted()
        }
        if textField.text?.count ?? 0 >= 19{
            submit.isEnabled = true
            submit.backgroundColor = #colorLiteral(red: 0.007843137255, green: 0.431372549, blue: 0.768627451, alpha: 1)
            studyCodeTextField.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }else{
            submit.isEnabled = false
            submit.backgroundColor = #colorLiteral(red: 0.5322797894, green: 0.6935800314, blue: 0.8115844131, alpha: 1)
        }
        return false
    }
    
    @objc func validateStudyCode(){
        if studyCodeTextField.hasText{
            submit.isEnabled = false
            submit.backgroundColor = #colorLiteral(red: 0.5322797894, green: 0.6935800314, blue: 0.8115844131, alpha: 1)
            let codeWithDashes = studyCodeTextField.text?.lowercased()
            let code = codeWithDashes?.replacingOccurrences(of: " ", with: "")
            
            //Using bit-shifts for exponentiation (since there is no operator)
            let waitTime = 2 << AppDelegate.requestCount
            
            
            DispatchQueue.main.async {
                self.blurEffectView?.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.blurEffectView?.effect = UIBlurEffect(style: .light)
                })
                self.spinner.startAnimating()
            }
            //Create deadlock before checking if request was successful.
            let group = DispatchGroup()
            group.enter()
            
            //Check if code is the proper length before making a request.
            if (code!.count == 16){
                //Wait time implements exponential backoff depending on number of attempts
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(waitTime), execute: {
                    AppDelegate.requestCount += 1
                    //params: code
                    var request = URLRequest(url: NSURL(string: "\(studyCodeVerificationURL)?code=\(code!)")! as URL)
                    request.httpMethod = "GET"

                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        guard let data = data, error == nil else {                                                 // check for fundamental networking error
                            
                            NSLog("error=\(String(describing: error))")
                            self.errorResponse = true
                            //Guess it wasn't their fault, decrement exponential backoff
                            AppDelegate.requestCount -= 1
                            group.leave()
                            return
                        }
                        
                        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                            NSLog("statusCode should be 200, but is \(httpStatus.statusCode)")
                        }
                        
                        var responseString = String(data: data, encoding: .utf8)
                        //Wrap response in brackets so it fits JSON format
                        responseString = "[\(responseString!)]"
                        //print("\(responseString)")
                        let data2 = responseString!.data(using: .utf8)!
                        //Unwrap JSON response
                        do {
                            if let jsonArray = try JSONSerialization.jsonObject(with: data2, options : .allowFragments) as? [Dictionary<String,Any>]
                            {
                                 // use the json here
                                if jsonArray[0].keys.contains("study"){
                                    self.study = jsonArray[0]["study"] as! String
                                    self.studyCodeClaimed = jsonArray[0]["claimed"] as! Bool
                                    self.studyCodeCreationDate = jsonArray[0]["studyCodeCreationDate"] as! String
                                    //reset exponential backoff
                                    AppDelegate.requestCount = 0
                                    self.shake = false
                                }
                                if jsonArray[0].keys.contains("message"){
                                    let message = jsonArray[0]["message"] as! String
                                    if message == "study code has already been claimed!"{
                                        //print("already claimed!")
                                        self.studyCodeClaimed = true
                                        //reset exponential backoff
                                        AppDelegate.requestCount = 0
                                        self.shake = false
                                    }
                                }
                            } else {
                                //print("bad json")
                                //self.studyCodeTextField.isError(baseColor: UIColor.gray.cgColor, numberOfShakes: 3, revert: true)
                            }
                        } catch let error as NSError {
                            NSLog("error: \(error)")
                            //self.studyCodeTextField.isError(baseColor: UIColor.gray.cgColor, numberOfShakes: 3, revert: true)
                        }
                        group.leave()
                        
                    }
                    task.resume()
                    
                })
                //execute after request has completed.
                group.notify(queue: .main) {
                    self.submit.isEnabled = true
                    self.submit.backgroundColor = #colorLiteral(red: 0.007843137255, green: 0.431372549, blue: 0.768627451, alpha: 1)
                    if self.shake{
                        //Failed
                        if self.errorResponse{
                            //Request failed because it could not connect to the internet.
                            self.errorResponse = false
                            let alert = UIAlertController(title: "badCodeTitle".localized(), message: "badCodeMessage".localized(), preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Okay".localized(), style: .default, handler: nil))
                            self.present(alert, animated: true)
                        
                        }
                        //self.studyCodeTextField.isError(baseColor: UIColor.gray.cgColor, numberOfShakes: 3, revert: true)
                    }else{
                        if self.studyCodeClaimed{
                            //self.studyCodeTextField.isError(baseColor: UIColor.gray.cgColor, numberOfShakes: 3, revert: true)
                            let alert = UIAlertController(title: "claimedCodeTitle".localized(), message: "claimedCodeMessage".localized(), preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Okay".localized(), style: .default, handler: nil))
                            self.present(alert, animated: true)
                            self.shake = true
                        }else{
                            //Success, return to pageViewController and present consent document.
                            self.delegate?.handShake(controller: self, text: self.study, studyVars:[code!,self.study,self.studyCodeCreationDate])
                        }
                    }
                    //always stop animation
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.5, animations: {
                            self.blurEffectView?.effect = nil
                        })
                        self.spinner.stopAnimating()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                        self.blurEffectView?.isHidden = true
                        if self.shake{
                            self.studyCodeTextField.isError(baseColor: UIColor.gray.cgColor, numberOfShakes: 3, revert: true)
                        }
                    })
                }
                
            }else{
                //failed
                self.studyCodeTextField.isError(baseColor: UIColor.gray.cgColor, numberOfShakes: 3, revert: true)
            }
        }
    }
    @objc func back(){
        delegate?.handShake(controller: self, text: "back",studyVars:[""])

    }
    @objc func qrCode(){
        weak var vc = storyboard?.instantiateViewController(withIdentifier: "QRCodeVC") as? QRCodeVC
        vc!.delegate = self
        vc!.modalTransitionStyle = .crossDissolve
        present(vc!, animated: true, completion: nil)
    }
    
    func handShake(controller:QRCodeVC, text:String){
        //NSLog("recieved")
        if (text.count == 16) && text.isAlphanumeric(){
            let newText = String((text.uppercased())
                .filter({ $0 != " " }).prefix(16))
            studyCodeTextField.text = newText.chunkFormatted()
            submit.isEnabled = true
            submit.backgroundColor = #colorLiteral(red: 0.007843137255, green: 0.431372549, blue: 0.768627451, alpha: 1)
            studyCodeTextField.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            controller.dismiss(animated: true, completion: nil)
        }else{
            controller.dismiss(animated: true, completion: nil)
            let alert = UIAlertController(title: "invalidQRTitle".localized(), message: "invalidQRMessage".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay".localized(), style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
        //print("studySelectVC deinit invoked.")
    }
    
    // Move textfield when keyboard appears swift
    // https://stackoverflow.com/questions/25693130/move-textfield-when-keyboard-appears-swift
    var minY:CGFloat = 0
    var newMinY:CGFloat = 0

    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint?.constant = originalHeight!
                self.topLayoutConstraint?.constant = topOriginalHeight!
                //print("frame.minY: \(self.studyCodeTextField.frame.minY)")
                //print("topOriginalHeight!: \(topOriginalHeight!)")
                minY = 0
                qrButton.isHidden = false

            } else {
                self.keyboardHeightLayoutConstraint?.constant = (endFrame?.size.height ?? 0.0) + 40
                //print("\(self.studyCodeTextField.frame.minY)")
                qrButton.isHidden = true
                if minY == 0{
                    minY = self.studyCodeTextField.frame.minY - 40
                }
                self.topLayoutConstraint?.constant = (topOriginalHeight! - (view.frame.height - minY))
                //print("frame.minY: \(self.studyCodeTextField.frame.minY)")
                //print("topOriginalHeight!: \(topOriginalHeight!)")
                //print("view.frame.height: \(view.frame.height)")
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    func customStringFormatting(of str: String) -> String {
        return str.chunk(n: 4)
            .map{ String($0) }.joined(separator: " ")
    }

}

// @SpanTag Answer for Displaying validation error on ios uitextfield similar to androids textview set
// https://stackoverflow.com/questions/30574484/displaying-validation-error-on-ios-uitextfield-similar-to-androids-textview-set
extension UITextField {
    func setBottomBorderOnlyWith(color: CGColor) {
        self.borderStyle = .none
        self.layer.masksToBounds = false
        self.layer.shadowColor = color
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

extension UITextField {
    func isError(baseColor: CGColor, numberOfShakes shakes: Float, revert: Bool) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "shadowColor")
        animation.fromValue = baseColor
        animation.toValue = UIColor.red.cgColor
        animation.duration = 0.4
        if revert { animation.autoreverses = true } else { animation.autoreverses = false }
        self.layer.add(animation, forKey: "")
        
        let shake: CABasicAnimation = CABasicAnimation(keyPath: "position")
        shake.duration = 0.07
        shake.repeatCount = shakes
        if revert { shake.autoreverses = true  } else { shake.autoreverses = false }
        shake.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        shake.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(shake, forKey: "position")
    }
}

// Check if a String is alphanumeric in Swift
// https://stackoverflow.com/questions/35992800/check-if-a-string-is-alphanumeric-in-swift
extension String {
    
    func isAlphanumeric() -> Bool {
        return self.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil && self != ""
    }
    
    func isAlphanumeric(ignoreDiacritics: Bool = false) -> Bool {
        if ignoreDiacritics {
            return self.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && self != ""
        }
        else {
            return self.isAlphanumeric()
        }
    }
    func chunkFormatted(withChunkSize chunkSize: Int = 4,
                        withSeparator separator: Character = " ") -> String {
        return self.filter { $0 != separator }.chunk(n: chunkSize)
            .map{ String($0) }.joined(separator: String(separator))
    }
    
}

/* Swift 3 version of Github use oisdk:s SwiftSequence's 'chunk' method:
 https://github.com/oisdk/SwiftSequence/blob/master/Sources/ChunkWindowSplit.swift */
extension Collection {
    public func chunk(n: Int) -> [SubSequence] {
        var res: [SubSequence] = []
        var i = startIndex
        var j: Index
        while i != endIndex {
            j = index(i, offsetBy: n, limitedBy: endIndex) ?? endIndex
            res.append(self[i..<j])
            i = j
        }
        return res
    }
}
