//
//  ViewController.swift
//  Volna
//
//  Created by Artem Malyshev on 8/12/16.
//  Copyright © 2016 Artem Malyshev. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
    
    private var player = AVPlayer()
    private var currentStation = ""
    private var radioStations = [
        "Echo FM" : AVPlayerItem( URL:NSURL( string:"http://streaming211.radionomy.com:80/MRJazz" )!),
        "Business FM" : AVPlayerItem( URL:NSURL( string:"http://streaming211.radionomy.com:80/MRJazz" )!),
        "Relax FM" : AVPlayerItem( URL:NSURL( string:"http://streaming211.radionomy.com:80/MRJazz" )!)
        
    ]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(radioStations["Relax FM"])
        player.volume = 1.0
//        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        print("end")
        player.replaceCurrentItemWithPlayerItem(radioStations["Relax FM"])
        player.play()
    }

    @IBAction func playStation() {
        print("play")
        print(player.volume)
        if (player.rate != 0) {
            player.pause()
        } else {
            player.play()
            print(player.currentItem)
            print(player.rate)
        }
        
    }
    @IBAction func setStation(sender: UIButton) {
        print("set")
        if radioStations.keys.contains(sender.currentTitle!) {
            player.replaceCurrentItemWithPlayerItem(radioStations[sender.currentTitle!])
//            playStation()
        }
    }
    
}

