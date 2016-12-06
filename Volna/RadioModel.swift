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
    private var radioStations: Dictionary<String,String>
    private var currentStation: String?
    
    init() {
        player = AVPlayer()
        radioStations = [
            "Echo FM" : "http://stream05.media.rambler.ru/echo.mp3",
            "Business FM" : "www",
            "Relax FM" : "http://stream01.media.rambler.ru:80/relax128.mp3"
            
        ]
    }
   
    func setStation(_ station: String) {
        if radioStations.keys.contains(station) {
            player.replaceCurrentItem(with: AVPlayerItem( url:URL( string:radioStations[station]!)!))
            currentStation = station
            if isPaused() { play() }
        }
    }
    
    private func isPaused() -> Bool {
        return player.rate == 0
    }
    private func isPlayBackBufferFull() -> Bool {
        return player.currentItem!.isPlaybackBufferFull
    }
    func play() {
        if isPaused() {
            player.play()
        } else {
            player.pause()
        }
        print(isPaused())
        print(player.volume)
        print(player.rate)
        if isPlayBackBufferFull() {
            setStation(currentStation!)
        }
    }
    
}
