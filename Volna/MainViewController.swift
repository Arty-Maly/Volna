//  Created by Artem Malyshev.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import GoogleMobileAds

class MainViewController: UIViewController, MainViewPageControlDelegate, GADBannerViewDelegate {
  private var player: RadioPlayer
  private var playImage: UIImage
  private var pauseImage: UIImage
  private var previousStationPosition: Int?
  private var currentStationPosition: Int?
  private let infoCenter: MPNowPlayingInfoCenter
  private var radioPage: RadioPageViewController?
  private var currentStation: RadioStation?
  private var managedObjectContext: NSManagedObjectContext?
  private var wasPlaying: Bool
  weak var buttonDelegate: ButtonActionDelegate?
  @IBOutlet weak var favouriteButton: FavouriteButton!
  @IBOutlet weak var adView: UIView!
  @IBOutlet weak var adViewHeight: NSLayoutConstraint!
  
  lazy var adBannerView: GADBannerView = {
    let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
    adBannerView.rootViewController = self
    adBannerView.adUnitID = Constants.adUnitID
    adBannerView.delegate = self
    
    return adBannerView
  }()

  @IBOutlet weak var pageControl: UIPageControl!
  
  @IBOutlet weak var bottomBar: UIView!
  @IBOutlet weak var stationTitle: UILabel!
  @IBOutlet weak var playButton: UIButton!
  
  required init(coder aDecoder: NSCoder) {
    player = RadioPlayer()
    playImage = UIImage(named: "play_button.png")!
    pauseImage = UIImage(named: "pause_button.png")!
    infoCenter = MPNowPlayingInfoCenter.default()
    wasPlaying = false
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let request = GADRequest()
    adBannerView.load(request)
    adBannerView.load(GADRequest())
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
  
  override func viewDidAppear(_ animated: Bool) {
    let userInfo = User.getTimesOpenedAndAskForReview()
    if userInfo.0 % Constants.timesOpened == 0 && userInfo.1 {
      let alert = ReviewPromptController()
      self.present(alert.alertController, animated: true)
      User.incrementTimesOpened()
    } else {
      User.incrementTimesOpened()
    }
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
          togglePlayButton()
        case .ended:
          print("ended")
          guard let optionsValue =
            info[AVAudioSessionInterruptionOptionKey] as? UInt else {
              return
          }
          let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
          if options.contains(.shouldResume) && wasPlaying {
            player.resumePlayAfterInterrupt()
            print("resume playback")
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
    if let currentPosition = (player.currentStation?.position) {
      let totalStations = RadioStation.getStationCount(inManagedContext: managedObjectContext!)
      let nextPosition = Int(currentPosition) + 1 < totalStations ? Int(currentPosition) + 1 : 0
      let station = RadioStation.getStationByPosition(position: nextPosition, inManagedContext: managedObjectContext!)
      setStation(station)
      buttonDelegate?.updateCurrentStation(station: station)
//      player.player.play()
    }
  }
  
  @objc private func prevStation() {
    if let currentPosition = (player.currentStation?.position) {
      let totalStations = RadioStation.getStationCount(inManagedContext: managedObjectContext!)
      let prevPosition = Int(currentPosition) - 1 < 0 ? totalStations - 1 : Int(currentPosition) - 1
      let station = RadioStation.getStationByPosition(position: prevPosition, inManagedContext: managedObjectContext!)
      setStation(station)
      buttonDelegate?.updateCurrentStation(station: station)
    }
  }
  
  private func setStation(_ station: RadioStation) {
    player.setStation(station)
    currentStation = station
    stationTitle.text = station.name
    previousStationPosition = currentStationPosition
    currentStationPosition = Int(station.position)
    let image = ImageCache.shared[station.image]
    togglePauseButton()
    let albumArtWork = MPMediaItemArtwork(image: image!.toSquare())
    infoCenter.nowPlayingInfo = [
      MPMediaItemPropertyArtwork:albumArtWork,
      MPMediaItemPropertyTitle:station.name]
    toggleFavouriteButton()
    wasPlaying = true
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
      wasPlaying = false
    } else {
      togglePauseButton()
    }
  }
  
  func change(station: RadioStation) {
    print(station)
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
  
  func adViewDidReceiveAd(_ bannerView: GADBannerView) {
    print("Banner loaded successfully")
//    self.adView.addSubview(adBannerView)
//    adView?.frame = bannerView.frame
    
//    print(adView.frame.size.width)
//    print(adView.frame.size.height)
//    adView.frame.size.height = adBannerView.frame.size.height
//    adView.frame.size.width = adBannerView.frame.size.width
//    print(adView.frame)
//    print(adView.frame.size.width)
//    print(adView.frame.size.height)
//    
//    adView.addSubview(adBannerView)
//    let translateTransform = CGAffineTransform(translationX: 0, y: -bannerView.bounds.size.height)
//    bannerView.transform = translateTransform
    adViewHeight?.isActive = false
    self.adView.addSubview(bannerView)
    
    UIView.animate(withDuration: 0.5) {
      self.adView.frame.size.height = bannerView.frame.size.height
      self.adView.frame.size.width = bannerView.frame.size.width
//      bannerView.transform = CGAffineTransform.identity
    }
  }
}

