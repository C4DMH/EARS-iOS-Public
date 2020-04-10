//
//  MusicManager.swift
//  EARS
//
//  Created by Wyatt Reed on 7/30/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import MediaPlayer

class MusicManager {
    
    lazy var musicDataString = "MUS"
    //static var buffer = Array<UInt8>(repeating: 0, count: 0)
    
    static let player = MPMusicPlayerController.systemMusicPlayer
    var timer = Timer()
    
    init(){
        MusicManager.player.beginGeneratingPlaybackNotifications()
        
    }
    
    func recordMusic(songInfo: Research_MusicEvent){
        //print("\(songInfo)")
        let dataStorage = DataStorage()
        dataStorage.writeFileProto(dataType: self.musicDataString, messageArray: [songInfo])
    }
    
}
