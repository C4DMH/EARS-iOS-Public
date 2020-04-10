//
//  GradientVC.swift
//  EARS
//
//  Created by Wyatt Reed on 7/6/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import UIKit

/// Creates a gradient background that animates an ebb and flow
class GradientVC: UIViewController {

    @IBOutlet weak var gradientView: UIView!
    
    
    let gradient = CAGradientLayer()
    var gradientSet = [[CGColor]]()
    var currentGradient: Int = 0
    
    let gradientOne = UIColor(red: 0/255, green: 117/255, blue: 225/255, alpha: 1).cgColor
    let gradientTwo = UIColor(red: 18/255, green: 55/255, blue: 114/255, alpha: 1).cgColor
    let gradientThree = UIColor(red: 8/255, green: 190/255, blue: 216/255, alpha: 1).cgColor
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientSetup()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    private func animateGradient() {
        if currentGradient < gradientSet.count - 1 {
            currentGradient += 1
        } else {
            currentGradient = 0
        }
        
        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.duration = 15.0
        gradientChangeAnimation.autoreverses = true
        gradientChangeAnimation.repeatCount = Float.infinity
        gradientChangeAnimation.toValue = gradientSet[currentGradient]
        gradientChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradient.add(gradientChangeAnimation, forKey: "colorChange")
    }
    
    private func gradientSetup() {
        gradientSet.append([gradientThree, gradientTwo])
        gradientSet.append([gradientOne, gradientTwo])
        gradientSet.append([gradientTwo, gradientOne])
        gradientSet.append([gradientTwo, gradientThree])
        
        
        //gradient.frame = gradientView.bounds
        gradient.startPoint = CGPoint(x:0, y:0)
        gradient.endPoint = CGPoint(x:1, y:1)
        gradient.drawsAsynchronously = true
        gradient.frame = UIScreen.main.bounds
        
        if !UIAccessibility.isReduceMotionEnabled {
            gradient.colors = gradientSet[currentGradient]
            self.view.layer.insertSublayer(gradient, at: 0)
            animateGradient()
        }else{
            gradient.colors = gradientSet[1]
            self.view.layer.insertSublayer(gradient, at: 0)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    deinit {
        //print("Gradient deinit invoked.")
    }
    
}

extension GradientVC: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            gradient.colors = gradientSet[currentGradient]
            animateGradient()
        }
    }
}
