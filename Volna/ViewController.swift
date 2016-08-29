//
//  ViewController.swift
//  Volna
//
//  Created by Artem Malyshev on 8/12/16.
//  Copyright © 2016 Artem Malyshev. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var player:AVPlayer!
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = "http://streaming211.radionomy.com:80/MRJazz"
        let url_item = AVPlayerItem( URL:NSURL( string:url )!)
        player = AVPlayer(playerItem:url_item)
//        player.rate = 1.0
//        player.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func press() {
        if (player.rate != 0) {
            player.pause()
        } else {
            player.play()
        }
    }
    @IBOutlet weak var bottom: UIView!
//
//    @IBAction func buttonPress(sender: AnyObject) {
//        if (player.rate != 0) {
//            player.pause()
//        } else {
//            player.play()
//        }
//    }
    @IBAction func jiesButton() {
    }

}

