//
//  RadioModel.swift
//  Volna
//
//  Created by Artem Malyshev on 9/9/16.
//  Copyright © 2016 Artem Malyshev. All rights reserved.
//

import Foundation
import AVFoundation

class RadioModel {
    private var player: AVPlayer
    private var currentStation: String
    private var radioStations: Dictionary<String,AVPlayerItem>
    
    init() {
        player = AVPlayer()
        currentStation = ""
        radioStations = [
            "Echo FM" : AVPlayerItem( URL:NSURL( string:"http://stream05.media.rambler.ru/echo.mp3" )!),
            "Business FM" : AVPlayerItem( URL:NSURL( string:"http://stream02.media.rambler.ru:80/bizmsk128.mp3" )!),
            "Relax FM" : AVPlayerItem( URL:NSURL( string:"http://stream01.media.rambler.ru:80/relax128.mp3" )!)
            
        ]
//        do {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
//        } catch {
//            print("Error")
//        }

    }
    
   
    func setStation(station: String) {
        if radioStations.keys.contains(station) {
            player.replaceCurrentItemWithPlayerItem(radioStations[station])
            playStation()
        }
    }
    
    func playStation() {
        if (player.rate != 0) {
            player.pause()
        } else {
            player.play()
        }
        
    }
    
}
