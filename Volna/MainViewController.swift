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
import Reachability


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
        showAlertsIfNeeded()
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
                    if options.contains(.shouldResume) {
                        recoverPlayback()
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
    
    private func showAlertsIfNeeded() {
        let userInfo = User.getTimesOpenedAndAskForReview()
        if userInfo.0 == 1 {
            let infoAlert = InfoAlert(alertWidth: bottomBar.frame.size.width - 40)
            infoAlert.showAlert()
        }
        if userInfo.0 % Constants.timesOpened == 0 && userInfo.1 {
            let reviewPrompt = ReviewPromptController(alertWidth: bottomBar.frame.size.width - 40)
            reviewPrompt.showAlert()
            Logger.logReviewPresented(numberOfTimes: userInfo.0)
        }
    }
    
    private func loadAdRequest() {
        adView.rootViewController = self
        adView.adUnitID = Constants.adUnitID
        adView.delegate = self
        let request = GADRequest()
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
        guard currentStation != nil else { return }
        togglePlaybackButton()
        player.togglePlayback()
    }
    
    @objc private func nextStation() {
        if let currentPosition = (player.currentStation?.position) {
            let totalStations = RadioStation.getStationCount(inManagedContext: managedObjectContext!)
            let nextPosition = Int(currentPosition) + 1 < totalStations ? Int(currentPosition) + 1 : 0
            let station = RadioStation.getStationByPosition(position: nextPosition, inManagedContext: managedObjectContext!)
            setStation(station, shouldStartPlayback: false)
            buttonDelegate?.updateCurrentStation(station: station)
        }
    }
    
    @objc private func prevStation() {
        if let currentPosition = (player.currentStation?.position) {
            let totalStations = RadioStation.getStationCount(inManagedContext: managedObjectContext!)
            let prevPosition = Int(currentPosition) - 1 < 0 ? totalStations - 1 : Int(currentPosition) - 1
            let station = RadioStation.getStationByPosition(position: prevPosition, inManagedContext: managedObjectContext!)
            setStation(station, shouldStartPlayback: false)
            buttonDelegate?.updateCurrentStation(station: station)
        }
    }
    
    private func setStation(_ station: RadioStation, shouldStartPlayback startPlayback: Bool = true) {
        player.setStation(station, shouldStartPlayback: startPlayback)
        setStationInfo(station)
        togglePauseButton()
        wasPlaying = true
    }
    
    private func setStationInfo(_ station: RadioStation) {
        currentStation = station
        stationTitle.text = station.name
        previousStationPosition = currentStationPosition
        currentStationPosition = Int(station.position)
        let image = ImageCache.shared[station.image]
        playbackImage.image = image
        let albumArtWork = MPMediaItemArtwork(image: image!.toSquare())
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
        togglePauseButton()
        playbackIndicator.state = .paused
    }
    
    @objc private func checkForReachability(_ notification: Notification) {
        guard let networkReachability = notification.object as? Reachability else {
            return
        }
        let remoteHostStatus = networkReachability.currentReachabilityStatus()
        
        switch remoteHostStatus {
        case .NotReachable:
            playbackStalled()
        default: ()
        recoverPlayback()
        }
    }
    
    private func recoverPlayback() {
        if wasPlaying {
            player.resumePlayAfterInterrupt()
        } else {
            return
            //      player.prepareForPlayback()
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        case .oldDeviceUnavailable:
            wasPlaying = false
        default: ()
        }
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: .AVAudioSessionRouteChange,
                                               object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(checkForReachability),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)
        let reachability = Reachability.forInternetConnection()
        reachability?.startNotifier()
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
        playbackIndicator.state = .paused
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
        guard currentStation == nil else { return }
        if stationTitle.text == Constants.greetingTitle {
            stationTitle.text = Constants.favouriteTitle
        } else {
            stationTitle.text = Constants.greetingTitle
        }
    }
    
    func playbackStalled() {
        togglePlayButton()
        player.stopPlayback()
        playbackIndicator.state = .paused
    }
    
    func startPlaybackIndicator() {
        if wasPlaying {
            playbackIndicator.state = .playing
            togglePauseButton()
        }
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

