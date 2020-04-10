//
//  NetworkReachabilityManager.swift
//  EARS
//
//  Created by Wyatt Reed on 8/3/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import Reachability

class NetworkReachabilityManager: NSObject{
    static let shared = NetworkReachabilityManager()
    let networkStateList = ["none","wifi","cellular"]
    static var reachabilityState: String = "unknown"
    var reachability: Reachability!
    override init(){
        self.reachability = Reachability()
        
    }
    deinit{
        self.reachability = nil
    }
    
    func reachabilityChanged() {
    
        switch reachability.connection  {
            case .none:
                NetworkReachabilityManager.reachabilityState = networkStateList[0]
                //print(NetworkReachabilityManager.reachabilityState)
            case .wifi:
                NetworkReachabilityManager.reachabilityState = networkStateList[1]
                //print(NetworkReachabilityManager.reachabilityState)
            case .cellular:
                NetworkReachabilityManager.reachabilityState = networkStateList[2]
                //print(NetworkReachabilityManager.reachabilityState)
        }
    }
    func getNetworkState() -> String{
        reachabilityChanged()
        return NetworkReachabilityManager.reachabilityState
    }
    
}
