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
import MarqueeLabel

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
    private let defaults: UserDefaults
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
    @IBOutlet weak var artistTitle: MarqueeLabel!
    @IBOutlet weak var songTitle: MarqueeLabel!
    
    required init(coder aDecoder: NSCoder) {
        player = RadioPlayer()
        playImage = UIImage(named: "play_button")!
        pauseImage = UIImage(named: "pause_button")!
        infoCenter = MPNowPlayingInfoCenter.default()
        wasPlaying = false
        defaults = UserDefaults.standard
        super.init(coder: aDecoder)!
        player.playbackDelegate = self
    }
    
    override func viewDidLoad() {
        setAvAudioSession()
        loadAdRequest()
        playbackIndicator.tintColor = .white
        startUserActivity()
        managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
        let radioPage = self.childViewControllers[0] as! RadioPageViewController
        radioPage.mainDelegate = self
        buttonDelegate = radioPage
        setRemoteCommandCenter()
        addObservers()
        setTitle()
        setUpNowPlayingLabel(songTitle)
        setUpNowPlayingLabel(artistTitle)
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showAlertsIfNeeded()
        User.incrementTimesOpened()
    }
    
    private func setUpNowPlayingLabel(_ label: MarqueeLabel) {
        label.type = .continuous
        label.speed = .rate(20.0)
        label.animationCurve = .linear
        label.fadeLength = 10.0
    }
    
    private func setTitle() {
        if defaults.bool(forKey: Constants.startFromFavourites) {
            stationTitle.text = Constants.favouriteTitle
        }
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
            if #available(iOS 10.3, *) {
                return
            } else {
                let reviewPrompt = ReviewPromptController(alertWidth: bottomBar.frame.size.width - 40)
                reviewPrompt.showAlert()
                Logger.logReviewPresented(numberOfTimes: userInfo.0)
            }
        }
    }
    
    private func loadAdRequest() {
        adContainer.frame.size.height = Constants.adContainerHeight
        adView.frame.size.height = Constants.adContainerHeight
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
        guard let playbackButtonImage = playButton.image(for: .normal) else { return }
        if playbackButtonImage.isEqual(playImage) {
            player.play()
            togglePauseButton()
        } else {
            player.pause()
            togglePlayButton()
            wasPlaying = false
        }
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
        wasPlaying = true
        if startPlayback { togglePauseButton() }
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
            MPMediaItemPropertyArtwork: albumArtWork,
            MPMediaItemPropertyTitle: station.name
        ]
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
        guard let playbackButtonImage = playButton.image(for: .normal) else { return }
        if playbackButtonImage.isEqual(playImage) {
            togglePauseButton()
        } else {
            togglePlayButton()
            wasPlaying = false
        }
    }
    
    @objc private func playerItemFailedToPlay() {
        print("player failed to play")
        togglePlayButton()
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
        stopPlaybackIndicator()
         NSObject.cancelPreviousPerformRequests(withTarget: self)
        if wasPlaying {
            player.play()
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
        artistTitle.text = ""
        songTitle.text = ""
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
    
    func updateControl(_ pageNumber: Int) {
        pageControl.currentPage = pageNumber
        guard pageNumber != 0 else {
            stationTitle.text = Constants.settingsTitle
            return
        }
        guard currentStation == nil else {
            stationTitle.text = currentStation?.name
            return
        }
        if pageNumber == 1 {
            stationTitle.text = Constants.greetingTitle
        } else {
           stationTitle.text = Constants.favouriteTitle
        }
    }
    
    func playbackStalled() {
//        togglePlayButton()
        player.stopPlayback()
        playbackIndicator.state = .paused
        perform(#selector(setWasPlayingToFalse), with: nil, afterDelay: 60)
    }
    
    @objc private func setWasPlayingToFalse() {
        if wasPlaying {
            wasPlaying = false
        }
    }
    
    func startPlaybackIndicator() {
        wasPlaying = true
        playbackIndicator.state = .playing
        togglePauseButton()
    }
    
    func stopPlaybackIndicator() {
        playbackIndicator.state = .paused
        togglePlayButton()
    }
    
    func updateStationMetadata(with data: StationMetadata) {
        guard let artist = data.artist, let title = data.songTitle else { return }
        infoCenter.nowPlayingInfo?["artist"] = artist
        infoCenter.nowPlayingInfo?["title"] = title
        artistTitle.text = artist
        songTitle.text = title
    }
    
    func nativeExpressAdView(_ nativeExpressAdView: GADNativeExpressAdView, didFailToReceiveAdWithError error: GADRequestError) {
//        print("Banner load failure")
    }
    
    func nativeExpressAdViewDidReceiveAd(_ nativeExpressAdView: GADNativeExpressAdView) {
//        print("Banner loaded successfully")
        adContainer.isHidden = false
        let tempHeight = adView.frame.size.height
        adView.frame.size.height = 0
        nativeExpressAdView.alpha = 1.0
        UIView.animate(withDuration: 0.5) {
            self.adView.frame.size.height = tempHeight
        }
        adContainer.backgroundColor = Colors.lighterBlue
    }
}

