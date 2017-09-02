//  Created by Artem Malyshev.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import GoogleMobileAds
import ESTMusicIndicator
import SCLAlertView

class MainViewController: UIViewController, MainViewPageControlDelegate, GADNativeExpressAdViewDelegate, PlaybackDelegate {
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
  @IBOutlet weak var statusView: UIView!
  @IBOutlet weak var adView: GADNativeExpressAdView!
  @IBOutlet weak var adContainer: UIView!
  @IBOutlet weak var pageControl: UIPageControl!
  @IBOutlet weak var bottomBar: UIView!
  @IBOutlet weak var stationTitle: UILabel!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var playbackIndicator: ESTMusicIndicatorView!
  @IBOutlet weak var playbackImage: UIImageView!
  
  required init(coder aDecoder: NSCoder) {
    player = RadioPlayer()
    playImage = UIImage(named: "play_button")!
    pauseImage = UIImage(named: "pause_button")!
    infoCenter = MPNowPlayingInfoCenter.default()
    wasPlaying = false
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    player.playbackDelegate = self
    loadAdRequest()
    playbackIndicator.tintColor = .white
    startUserActivity()
    managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
    let radioPage = self.childViewControllers[0] as! RadioPageViewController
    radioPage.mainDelegate = self
    buttonDelegate = radioPage
    setRemoteCommandCenter()
    setAvAudioSession()
    addObservers()
    
    super.viewDidLoad()
  }

  override func viewDidAppear(_ animated: Bool) {
    let userInfo = User.getTimesOpenedAndAskForReview()
//    if userInfo.0 == 0 {
    let appearance = SCLAlertView.SCLAppearance(
      kCircleHeight: CGFloat(70),
      kCircleIconHeight: CGFloat(50),
      kTitleTop: CGFloat(40),
      kWindowWidth: CGFloat(bottomBar.frame.width - 40),
      kTitleFont: UIFont(name: "HelveticaNeue", size: 26)!,
      kTextFont: UIFont(name: "HelveticaNeue", size: 17)!,
      kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 17)!,
      showCloseButton: false,
      contentViewColor: Colors.lighterBlue,
      contentViewBorderColor: Colors.lighterBlue,
      titleColor: UIColor.white
    )
    var colorAsUInt : UInt32 = 0
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    if Colors.darkerBlue.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
      
      colorAsUInt += UInt32(red * 255.0) << 16 +
        UInt32(green * 255.0) << 8 +
        UInt32(blue * 255.0)
      
      colorAsUInt == 0xCC6699 // true
    }
    let alert = SCLAlertView(appearance: appearance)
    alert.addButton("OK", backgroundColor: Colors.darkerBlue, textColor: UIColor.white, showDurationStatus: true) {}
    let alertView = alert.showInfo(Constants.capabilitiesTitle, subTitle: Constants.capabilitiesText, colorStyle: UInt(colorAsUInt), circleIconImage: UIImage(named: "lightbulb"))
    
//    }
    if userInfo.0 % Constants.timesOpened == 0 && userInfo.1 {
      let alert = ReviewPromptController()
      self.present(alert.alertController, animated: true)
      Logger.logReviewPresented(numberOfTimes: userInfo.0)
    }
    User.incrementTimesOpened()
  }

  @objc private func playInterrupt(notification: NSNotification) {
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
  
  private func loadAdRequest() {
    adView.rootViewController = self
    adView.adUnitID = Constants.adUnitID
    adView.delegate = self
    let request = GADRequest()
    request.testDevices = ["a6a1484547eae253da0d4ccb01cdcfca"];
    adView.load(request)
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
    togglePlaybackButton()
    player.play()
  }
  @objc private func nextStation() {
    if let currentPosition = (player.currentStation?.position) {
      let totalStations = RadioStation.getStationCount(inManagedContext: managedObjectContext!)
      let nextPosition = Int(currentPosition) + 1 < totalStations ? Int(currentPosition) + 1 : 0
      let station = RadioStation.getStationByPosition(position: nextPosition, inManagedContext: managedObjectContext!)
      setStation(station)
      buttonDelegate?.updateCurrentStation(station: station)
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
    playbackImage.image = image
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
      togglePauseButton()
      wasPlaying = true
      playbackIndicator.state = .playing
    } else {
      wasPlaying = false
      togglePlayButton()
      playbackIndicator.state = .paused
    }
  }
  
  @objc private func playerItemFailedToPlay() {
    playbackIndicator.state = .paused
  }
  
  private func addObservers() {
    let audioSession = AVAudioSession.sharedInstance()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(self.playInterrupt),
                                           name: NSNotification.Name.AVAudioSessionInterruption,
                                           object: audioSession)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerItemFailedToPlay),
                                           name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                           object: nil)
  }
  
  private func startUserActivity() {
    let activity = NSUserActivity(activityType: Constants.activityType)
    
    activity.keywords = Set(Constants.searchKeywords)
    activity.isEligibleForSearch = true
    activity.title = Constants.activityTitle
    userActivity = activity
    userActivity!.becomeCurrent()
  }
  
  func change(station: RadioStation) {
    setStation(station)
    playbackIndicator.state = .playing
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
  
  func playbackStalled() {
    togglePlayButton()
    playbackIndicator.state = .paused
  }
  
  func nativeExpressAdViewDidReceiveAd(_ nativeExpressAdView: GADNativeExpressAdView) {
//    print("Banner loaded successfully")
    let tempHeight = adView.frame.size.height
    adView.frame.size.height = 0
    nativeExpressAdView.alpha = 1.0

    UIView.animate(withDuration: 0.5) {
      self.adView.frame.size.height = tempHeight
    }
    adContainer.backgroundColor = Colors.lighterBlue
  }
}

