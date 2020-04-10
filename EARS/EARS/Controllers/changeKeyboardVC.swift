//
//  changeKeyboardVC.swift
//  EARS
//
//  Created by Wyatt Reed on 12/10/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class changeKeyboardVC: UIViewController {

    @IBOutlet weak var buttonConstraint: NSLayoutConstraint!
    @IBOutlet weak var continueButton: roundedButton!
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var skip: UIButton!
    
    @IBOutlet weak var videoView: AVPlayerView!
    
    var originalHeight = CGFloat()
    var player: AVPlayer!
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        let maskLayer = CALayer()
        maskLayer.frame = videoView.layer.bounds.insetBy(dx: 1, dy: 1)
        maskLayer.backgroundColor = UIColor.white.cgColor
        videoView.layer.mask = maskLayer
        textField.isHidden = true
        
        playVideo()
        continueButton.isHidden = true
        originalHeight = buttonConstraint.constant
        
        if continueButton != nil {
            continueButton.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)
        }
        
        if skip != nil {
            skip.addTarget(self, action: #selector(changeDefault), for: .touchUpInside)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeKeyboardVC.changeInputMode(_:)),
                                               name: UITextInputMode.currentInputModeDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: CMTime.zero)
            self?.player?.play()
            
           
        }
        // Do any additional setup after loading the view.
        self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
        
    }
    @objc func handleTimer(timer: Timer){
        skip.isHidden = false
    }
    private func playVideo() {
        guard let path = Bundle.main.path(forResource: "ears-keyboard-animation", ofType:"mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        player = AVPlayer(url: URL(fileURLWithPath: path))
        
        let castedLayer = videoView.layer as! AVPlayerLayer
        castedLayer.player = player
        player.play()
        videoView.isHidden = false
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show keyboard by default
        textField.becomeFirstResponder()
        
    }
    @objc func changeDefault() {
        stopVideo()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if AppDelegate.study!.includedSensors["music"]!{
            appDelegate.changeRootViewController(with: "stepMusic")
        }else{
            if AppDelegate.study!.includedSensors["selfie"]!{
                appDelegate.changeRootViewController(with: "stepPhotoCapture")
            }else{
                appDelegate.changeRootViewController(with: "acknowledgement")
            }

        }
        
    }
    deinit{
        //print("stepSetup deinit invoked")
    }
    var switcher = false
    @objc func changeInputMode(_ notification: Notification)
    {
        
        if switcher{
            UIView.animate(withDuration: 1, animations: {
                self.continueButton.isHidden = false
                self.view.bringSubviewToFront(self.continueButton)
            })
            //videoView.isHidden = true
            addPlayerPeriodicObserver()
        }else{
            switcher = true
        }
 
        
    }
    var playerObserver: Any!

    func addPlayerPeriodicObserver() {
        
        removePlayerPeriodicObserver()
        
        // Time interval to check video playback.
        let interval = CMTime(seconds: 0.01, preferredTimescale: 1000)
        
        // Time limit to play up until.
        let duration = player.currentItem!.duration
        let limit = CMTime(seconds: 1.0, preferredTimescale: 1000)
        let maxTime = duration - limit
        
        // Schedule the event observer.
        playerObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [unowned self] time in
            
            if self.player.currentTime() >= maxTime {
                
                // Time is at or past time limits - stop the video.
                self.stopVideo()
            }
        }
    }
    func removePlayerPeriodicObserver() {
        
        if let playerObserver = playerObserver {
            player?.removeTimeObserver(playerObserver)
        }
        
        playerObserver = nil
    }
    
    func stopVideo() {
        
        removePlayerPeriodicObserver()
        player.pause()
    }

    

    // Move textfield when keyboard appears swift
    // https://stackoverflow.com/questions/25693130/move-textfield-when-keyboard-appears-swift
    
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.buttonConstraint?.constant = originalHeight
                //self.topLayoutConstraint?.constant = topOriginalHeight!
                //print("\(self.studyCodeTextField.frame.minY)")
            } else {
                self.buttonConstraint?.constant = (endFrame?.size.height ?? 0.0) + 7
                //print("\(self.studyCodeTextField.frame.minY)")
                //self.topLayoutConstraint?.constant = (topOriginalHeight! - (view.frame.height - self.studyCodeTextField.frame.minY)) - 7
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }

}

class AVPlayerView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
