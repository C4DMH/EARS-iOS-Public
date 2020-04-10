//
//  KeyboardInputManager.swift
//  EARS
//
//  Created by Wyatt Reed on 11/5/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import UIKit

class KeyboardInputManager {
    
    static var dataStorage = KeyboardDataStorage(dataType: "KeyInput")
    var openAccessEnabled = false
    static var uploadTime = ""
    
    init(){
        self.openAccessEnabled = isOpenAccessGranted()
        let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
        KeyboardInputManager.uploadTime = currentDateTime
    }
    
    deinit{
        //print("KeyboardInputManager deinit invoked.")
    }
    
    func isOpenAccessGranted() -> Bool{
        let originalString = UIPasteboard.general.string
        UIPasteboard.general.string = "CHECK"
        if UIPasteboard.general.hasStrings {
            UIPasteboard.general.string = originalString ?? ""
            return true
        }else{
            return false
        }
    }
    
    
    func recordAndWriteTextContext(AppString: String, textField: String){
        if textField.count != 0 {
            if openAccessEnabled{
                let keyboardProtoBuf = Research_KeyEvent.with {
                    $0.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                    $0.app = AppString
                    $0.textField = textField
                }
                
                KeyboardInputManager.dataStorage.writeFileProto(messageArray: [keyboardProtoBuf])
            }
           
        }
        
    }
    func incrementUploadCount(){
        let currentDateTime = String(Int64(Date().timeIntervalSince1970 * 1000))
        KeyboardInputManager.uploadTime = currentDateTime
    }
    
}
