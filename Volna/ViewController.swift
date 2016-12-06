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
    private var player: RadioModel
    
    @IBOutlet weak var scrollView: UIScrollView!
    required init(coder aDecoder: NSCoder) {
        player = RadioModel()
        super.init(coder: aDecoder)!
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            print(error.description)
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func playStation() {
        player.play()
        
        
    }
    
    @IBAction func setStation(_ sender: UIButton) {
        player.setStation(sender.currentTitle!)
    }
    
}

