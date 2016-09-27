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
    private var radioStations: Dictionary<String,AVPlayerItem>
    
    init() {
        player = AVPlayer()
        radioStations = [
            "Echo FM" : AVPlayerItem( url:URL( string:"http://stream05.media.rambler.ru/echo.mp3" )!),
            "Business FM" : AVPlayerItem( url:URL( string:"http://stream02.media.rambler.ru:80/bizmsk128.mp3" )!),
            "Relax FM" : AVPlayerItem( url:URL( string:"http://stream01.media.rambler.ru:80/relax128.mp3" )!)
            
        ]
    }
    
   
    func setStation(_ station: String) {
        if radioStations.keys.contains(station) {
            player.replaceCurrentItem(with: radioStations[station])
            if isPaused() { play() }
        }
    }
    private func isPaused() -> Bool {
        return player.rate == 0
    }
    
    func play() {
        if isPaused() {
            player.play()
        } else {
            player.pause()
        }
        
    }
    
}
