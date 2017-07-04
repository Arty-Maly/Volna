//  Created by Artem Malyshev.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import GoogleMobileAds

class MainViewController: UIViewController, MainViewPageControlDelegate {
  private var player: RadioPlayer
  private var playImage: UIImage
  private var pauseImage: UIImage
  private var previousStationPosition: Int?
  private var currentStationPosition: Int?
  private let infoCenter: MPNowPlayingInfoCenter
  private var radioPage: RadioPageViewController?
  private var currentStation: RadioStation?
  private var managedObjectContext: NSManagedObjectContext?
  weak var buttonDelegate: ButtonActionDelegate?
  @IBOutlet weak var favouriteButton: FavouriteButton!
  
  

  @IBOutlet weak var pageControl: UIPageControl!
  
  @IBOutlet weak var bannerView: GADBannerView!
  @IBOutlet weak var bottomBar: UIView!
  @IBOutlet weak var stationTitle: UILabel!
  @IBOutlet weak var playButton: UIButton!
  
  required init(coder aDecoder: NSCoder) {
    player = RadioPlayer()
    
    playImage = UIImage(named: "play_button.png")!
    pauseImage = UIImage(named: "pause_button.png")!
    infoCenter = MPNowPlayingInfoCenter.default()
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
//    bannerView.rootViewController = self
//    bannerView.load(GADRequest())
    managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
    let radioPage = self.childViewControllers[0] as! RadioPageViewController
    radioPage.mainDelegate = self
    buttonDelegate = radioPage
    setRemoteCommandCenter()
    setAvAudioSession()
    
    let audioSession = AVAudioSession.sharedInstance()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(self.playInterrupt),
                                           name: NSNotification.Name.AVAudioSessionInterruption,
                                           object: audioSession)
  }

  func playInterrupt(notification: NSNotification) {
    if notification.name == NSNotification.Name.AVAudioSessionInterruption
      && notification.userInfo != nil {
      
      var info = notification.userInfo!
      var intValue: UInt = 0
      (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
      if let type = AVAudioSessionInterruptionType(rawValue: intValue) {
        switch type {
        case .began:
          print("began")
          player.pause()
          togglePlayButton()
        case .ended:
          print("ended")
          guard let optionsValue =
            info[AVAudioSessionInterruptionOptionKey] as? UInt else {
              return
          }
          let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
          print(options)
          if options.contains(.shouldResume) {
            player.resumePlayAfterInterrupt()
            togglePauseButton()
          }
        }
      }
    }
  }
  
  private func setAvAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
      try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
    } catch {
      print(error)
    }
  }
  
  private func setRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled =  true
    commandCenter.previousTrackCommand.isEnabled =  true
    commandCenter.playCommand.addTarget(self, action: #selector(playStation))
    commandCenter.pauseCommand.addTarget(self, action: #selector(playStation))
    
    commandCenter.nextTrackCommand.addTarget(self, action: #selector(nextStation))
    commandCenter.previousTrackCommand.addTarget(self, action: #selector(prevStation))
  }
  
  @IBAction func playStation() {
    player.play()
    
    togglePlaybackButton()
  }
  
  @objc private func nextStation() {
    player.nextStation()
  }
  
  @objc private func prevStation() {
    player.prevStation()
  }
  
  private func setStation(_ station: RadioStation) {
    currentStation = station
    player.setStation(station)
    stationTitle.text = station.name
    previousStationPosition = currentStationPosition
    currentStationPosition = Int(station.position)
    let image = ImageCache.shared[station.image]
    togglePauseButton()
    let albumArtWork = MPMediaItemArtwork(image: image!)
    infoCenter.nowPlayingInfo = [
      MPMediaItemPropertyArtwork:albumArtWork,
      MPMediaItemPropertyTitle:station.name]
    toggleFavouriteButton()
  }
  
  private func toggleFavouriteButton() {
    guard let station = currentStation else {
      return
    }

    switch (favouriteButton.displayedState, station.favourite) {
    case (.active, false):
      favouriteButton.switchImage()
    case (.inactive, true):
      favouriteButton.switchImage()
    default:
      break
    }
    favouriteButton.isEnabled = true
    favouriteButton.isHidden = false
  }

  private func togglePlayButton() {
    playButton.setImage(playImage, for: .normal)
  }
  
  private func togglePauseButton() {
    playButton.setImage(pauseImage, for: .normal)
  }
  
  private func togglePlaybackButton() {
    if player.isPaused() {
      togglePlayButton()
    } else {
      togglePauseButton()
    }
  }
  
  func change(station: RadioStation) {
    setStation(station)
  }
  
  @IBAction func favouritedAction() {
    if let station = currentStation {
      station.toggleFavourite(context: managedObjectContext!)
      toggleFavouriteButton()
      buttonDelegate?.favouriteButtonPressed()
    }
  }
  
  func updateControl() {
    pageControl.currentPage = pageControl.numberOfPages - pageControl.currentPage - 1
  }
}

