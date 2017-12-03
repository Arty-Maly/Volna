//  Created by Artem Malyshev.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import Reachability
import MarqueeLabel
import MoPub

class MainViewController: UIViewController, MainViewPageControlDelegate, PlaybackDelegate, MPNativeAdDelegate {
    
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
    private var metadataContainerAlpha: CGFloat!
    private var metadataContainerIsHidden: Bool!
    private var expandArrowRotation: CGFloat!
    private let swipeLength: Double!
    private var animation: UIViewPropertyAnimator!
    private var startPoint: CGFloat!
    private var isUp = true
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var panRecognizer: UIPanGestureRecognizer!
    private var initialPoint: CGFloat!
    private var statusViewCornerRadius: CGFloat!
    private var mpNativeAd: MPNativeAd?
    private var mainAdRefreshtimer: RepeatingTimer!
    private var expandedAdRefreshtimer: RepeatingTimer!
    weak var buttonDelegate: ButtonActionDelegate?

    @IBOutlet weak var expandedMpNativeAdContainer: UIView!
    @IBOutlet var deflatedConstraints: [NSLayoutConstraint]!
    @IBOutlet var expandedConstraints: [NSLayoutConstraint]!
    
    @IBOutlet var favouriteButtons: [FavouriteButton]!
    @IBOutlet weak var metadataBorderContainer: PassThroughView!
    @IBOutlet weak var expandingPlayButtonContainer: UIView!
    @IBOutlet weak var expandArrowContainer: UIView!
    @IBOutlet weak var expandedMetadataContainer: UIView!
//    @IBOutlet weak var favouriteButton: FavouriteButton!
    @IBOutlet weak var stationImageBorderContainer: UIView!
    @IBOutlet weak var adContainer: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var stationTitle: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playbackImage: UIImageView!
    @IBOutlet weak var artistTitle: MarqueeLabel!
    @IBOutlet weak var fallbackTitle: MarqueeLabel!
    @IBOutlet weak var songTitle: MarqueeLabel!
    @IBOutlet weak var expandArrow: UIButton!
    @IBOutlet weak var metadataContainer: UIView!
    @IBOutlet weak var stationImage: UIView!
    @IBOutlet weak var fastForwardContainer: UIView!
    @IBOutlet weak var fastBackwardContainer: UIView!
    
    @IBAction func fastBackward(_ sender: Any) {
        playbackImage.slideInFromLeft()
        prevStation()
        
    }
    
    @IBAction func fastForward(_ sender: Any) {
        playbackImage.slideInFromRight()
        nextStation()
    }
    
    @IBAction func expandArrowTapped(_ sender: Any) {
        expandDetail()
    }
    
    private var isExpanded: Bool {
        didSet {
            if isExpanded {
                metadataContainerAlpha = 1.0
                metadataContainerIsHidden = false
                expandArrowRotation = .pi
                statusViewCornerRadius = 0.0
                toggleConstraints(active:  deflatedConstraints, innactive: expandedConstraints)
            } else {
                metadataContainerAlpha = 0.0
                metadataContainerIsHidden = true
                expandArrowRotation = 0.0
                statusViewCornerRadius = 10.0
                toggleConstraints(active: expandedConstraints, innactive: deflatedConstraints)
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        player = RadioPlayer()
        playImage = UIImage(named: "play_button_new_white")!
        pauseImage = UIImage(named: "pause_button_new_white")!
        infoCenter = MPNowPlayingInfoCenter.default()
        wasPlaying = false
        defaults = UserDefaults.standard
        isExpanded = false
        swipeLength = Constants.swipeLength
        mainAdRefreshtimer = RepeatingTimer(deadline: 0, interval: Constants.refreshAdRate)
        expandedAdRefreshtimer = RepeatingTimer(deadline: 3, interval: Constants.refreshAdRate)
        super.init(coder: aDecoder)!
        player.playbackDelegate = self
    }
    
    override func viewDidLoad() {
        setAvAudioSession()
//        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(loadExpandedAd), userInfo: nil, repeats: false)
//        mainAdRefreshtimer = Timer.scheduledTimer(timeInterval: TimeInterval(Constants.refreshAdRate), target: self, selector: #selector(loadMainAd), userInfo: nil, repeats: true)
        startUserActivity()
        managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
        let radioPage = self.childViewControllers[0] as! RadioPageViewController
        radioPage.mainDelegate = self
        buttonDelegate = radioPage
        setUpAdTimers()
        setRemoteCommandCenter()
        addObservers()
        setTitle()
        setUpNowPlayingLabel(fallbackTitle)
        setUpNowPlayingLabel(songTitle)
        setUpNowPlayingLabel(artistTitle)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(expandDetail))
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
//        expandingPlayButtonContainer.layer.addBorder(edge: .top, color: Colors.darkerBlue, thickness: 1)
//        expandingPlayButtonContainer.layer.borderColor = Colors.darkerBlue.cgColor
//        expandingPlayButtonContainer.layer.borderWidth = 1
        metadataContainerAlpha = 0.0
        metadataContainerIsHidden = true
        expandArrowRotation = 0.0
        statusViewCornerRadius = 10.0
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showAlertsIfNeeded()
        User.incrementTimesOpened()
    }
    
    private func setUpAdTimers() {
        mainAdRefreshtimer.eventHandler = loadMainAd
        mainAdRefreshtimer.resume()
        expandedAdRefreshtimer.eventHandler = loadExpandedAd
        expandedAdRefreshtimer.resume()
    }
    
    @objc private func didPan(sender:UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        let verticalPan = Double(translation.y)
        

        switch sender.state {
        case .began:
            startPoint = sender.location(in: self.view).y
            isExpanded = isExpanded ? false : true
            initialPoint = sender.location(in: self.view).y
            animation = UIViewPropertyAnimator(duration: Constants.animationDuration, curve: UIViewAnimationCurve.linear, animations: {
                self.view.layoutIfNeeded()
                self.setMetadataContainerViewProperties()
            })
            animation.addCompletion({ (position) in
                if position == .current  {
                    self.animateMetadataContainer()
                }
            })
            
            animation.fractionComplete = 0.0
        case .changed:
            isUp = startPoint - sender.location(in: self.view).y > 0 ? true : false
            startPoint = sender.location(in: self.view).y
            let percentageComplete = isExpanded ? CGFloat(-1 * verticalPan / swipeLength) : CGFloat(verticalPan / swipeLength)
            animation.fractionComplete = percentageComplete
        case .ended, .cancelled:
            if isUp == isExpanded {
                animation.startAnimation()
            } else {
                isExpanded = isExpanded ? false : true
                animation.stopAnimation(false)
                animation.finishAnimation(at: .current)
            }
        case .possible, .failed:
            break
        }
        
    }
    
    private func flipConstraints() {
        if isExpanded {
            toggleConstraints(active: expandedConstraints, innactive: deflatedConstraints)
        } else {
            toggleConstraints(active:  deflatedConstraints, innactive: expandedConstraints)
        }
    }
    
    private func toggleConstraints(active: [NSLayoutConstraint], innactive: [NSLayoutConstraint]) {
        //to avoid unsatisfiable constraints warnings first deactivate the active constraints
        active.forEach { constraint in
            constraint.isActive = false
        }
        innactive.forEach { constraint in
            constraint.isActive = true
        }
    }
    
    private func setMetadataContainerViewProperties() {
//        self.playButtonBorderContainer.alpha = metadataContainerAlpha
        self.fastForwardContainer.alpha = metadataContainerAlpha
        self.fastBackwardContainer.alpha = metadataContainerAlpha
        self.metadataContainer.alpha = metadataContainerAlpha
        self.stationImageBorderContainer.alpha = metadataContainerAlpha
        self.expandArrow.transform = CGAffineTransform(rotationAngle: expandArrowRotation)
        self.stationImage.layer.cornerRadius = statusViewCornerRadius
        self.metadataBorderContainer.alpha = metadataContainerAlpha
        
    }
    
    private func animateMetadataContainer() {
        UIView.animate(withDuration: Constants.animationDuration) {
            self.view.layoutIfNeeded()
            self.setMetadataContainerViewProperties()
        }
    }
    
    @objc private func expandDetail() {
        self.view.layoutIfNeeded()
        isExpanded = isExpanded ? false : true
        animateMetadataContainer()
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
    
//    private func loadAdMobRequest() {
//        adContainer.frame.size.height = Constants.adContainerHeight
//        adView.frame.size.height = Constants.adContainerHeight
//        adView.rootViewController = self
//        adView.adUnitID = Constants.adUnitID
//        adView.delegate = self
//        let request = GADRequest()
//        adView.load(request)
//    }
    
    @objc private func loadMainAd() {
        loadMopubRequest(adViewContainer: adContainer, renderingClass: MainAdView.self, adUnitId: Constants.mopubMainAdUnitIdentifier)
    }
    
    @objc private func loadExpandedAd() {
        loadMopubRequest(adViewContainer: expandedMpNativeAdContainer, renderingClass: NativeAdView.self, adUnitId: Constants.mopubSecondaryAdUnitIdentifier)
    }
    
    @objc private func loadMopubRequest(adViewContainer: UIView, renderingClass: UIView.Type, adUnitId: String) {
        DispatchQueue.main.async() {
            let settings = MPStaticNativeAdRendererSettings()
            settings.renderingViewClass = renderingClass
            guard let config = MPStaticNativeAdRenderer.rendererConfiguration(with: settings) else {
                Logger.logAdConfigCreationFailure()
                return
            }
            let adRequest = MPNativeAdRequest(adUnitIdentifier: adUnitId, rendererConfigurations: [config])
            let targeting = MPNativeAdRequestTargeting()
            targeting.desiredAssets = [kAdTitleKey, kAdTextKey, kAdCTATextKey, kAdIconImageKey, kAdMainImageKey, kAdStarRatingKey, kDAAIconTapDestinationURL, kDefaultActionURLKey]
            adRequest?.start(completionHandler: { (request, response, error) in
                self.setMopubReturnedAd(adViewContainer: adViewContainer, request: request, response: response, error: error)
            })
        }
    }
    
    private func setMopubReturnedAd(adViewContainer: UIView, request: MPNativeAdRequest?, response: MPNativeAd?, error: Error?) {
        guard error == nil else {
            Logger.logAdRequestFailure(error!)
            return
        }
        guard response != nil else { return }
        self.mpNativeAd = response!
        self.mpNativeAd!.delegate = self
        do {
            let mpNativeAdView =  try self.mpNativeAd!.retrieveAdView()
//            guard let view = mpNativeAdView else { return }
            mpNativeAdView.frame = adViewContainer.bounds
            let tempHeight = mpNativeAdView.frame.size.height
            mpNativeAdView.frame.size.height = 0
            adViewContainer.addSubview(mpNativeAdView)
            UIView.animate(withDuration: 0.3) {
               mpNativeAdView.frame.size.height = tempHeight
            }
        } catch let error {
            Logger.logAdRetrievalFailure(error)
        }
    }
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        return self
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
    
    private func setFallbackTitleToLoading() {
        artistTitle.text = ""
        songTitle.text = ""
        fallbackTitle.isHidden = false
        fallbackTitle.text = Constants.fallbackTitleLoadingText
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
        setFallbackTitleToLoading()
        player.setStation(station, shouldStartPlayback: startPlayback)
        setStationInfo(station)
        wasPlaying = true
        if startPlayback { togglePauseButton() }
    }
    
    private func setStationInfo(_ station: RadioStation) {
        stationImage.isHidden = false
        playbackImage.isUserInteractionEnabled = true
        playbackImage.addGestureRecognizer(tapGestureRecognizer)
        expandArrowContainer.isHidden = false
        bottomBar.addGestureRecognizer(panRecognizer)
        currentStation = station
        stationTitle.text = station.name
        previousStationPosition = currentStationPosition
        currentStationPosition = Int(station.position)
        let image = ImageCache.shared[station.image]
        
        playbackImage.image = image
        let artworkImage = image!.toSquare()
        let albumArtWork = MPMediaItemArtwork.init(boundsSize: artworkImage.size, requestHandler: { (size) -> UIImage in
            return artworkImage
        })
        
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
        favouriteButtons.forEach { favouriteButton in
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
        togglePlayButton()
        player.stopPlayback()
        if wasPlaying {
            player.play()
        } else {
            return
            //      player.prepareForPlayback()
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self)
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
        player.stopPlayback()
        perform(#selector(setWasPlayingToFalse), with: nil, afterDelay: 60)
    }
    
    @objc private func setWasPlayingToFalse() {
        if wasPlaying {
            wasPlaying = false
        }
    }
    
    func stopPlaybackIndicator() {
        togglePlayButton()
    }
    
    func startPlaybackIndicator() {
        wasPlaying = true
        fallbackTitle.text = Constants.fallbackMetadataText
    }
    
    func updateStationMetadata(with data: StationMetadata) {
        guard let artist = data.artist, let title = data.songTitle, title != "" else {
            fallbackTitle.text = Constants.fallbackMetadataText
            infoCenter.nowPlayingInfo?["artist"] = currentStation != nil ? currentStation?.name
                                                                            : ""
            infoCenter.nowPlayingInfo?["title"] = Constants.fallbackMetadataText
            fallbackTitle.isHidden = false
            return
        }
        guard artist != "" else {
            fallbackTitle.text = title
            infoCenter.nowPlayingInfo?["artist"] = currentStation != nil ? currentStation?.name
                : ""
            infoCenter.nowPlayingInfo?["title"] = title
            fallbackTitle.isHidden = false
            return
        }
        fallbackTitle.isHidden = true
        infoCenter.nowPlayingInfo?["artist"] = artist
        infoCenter.nowPlayingInfo?["title"] = title
        artistTitle.text = artist
        songTitle.text = title
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        adContainer.frame.size.width = size.width
    }
    
//    func nativeExpressAdView(_ nativeExpressAdView: GADNativeExpressAdView, didFailToReceiveAdWithError error: GADRequestError) {
//        print("Banner load failure")
//    }
    
//    func nativeExpressAdViewDidReceiveAd(_ nativeExpressAdView: GADNativeExpressAdView) {
////        print("Banner loaded successfully")
//        adContainer.isHidden = false
//        let tempHeight = adView.frame.size.height
//        adView.frame.size.height = 0
//        nativeExpressAdView.alpha = 1.0
//        UIView.animate(withDuration: 0.3) {
//            self.adView.frame.size.height = tempHeight
//        }
//        adContainer.backgroundColor = Colors.lighterBlue
//    }
}

