import Foundation
import AVFoundation
import UIKit

class RadioPlayer: NSObject {

    private(set) var player: AVPlayer
    private(set) var currentStation: RadioStation?
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var status: RadioPlayerStatus
    var playbackDelegate: PlaybackDelegate?
    
    private enum RadioPlayerStatus {
        case playing
        case paused
        case stalled
        case stopped
        case preparing
        
        mutating func transition() {
            switch self {
            case .stopped: self = .paused
            case .paused: self = .preparing
            case .preparing: self = .playing
            case .playing: self = .paused
            default: break
            }
        }
        
        mutating func transitionFromStalled() {
            switch self {
            case .stalled: self = .stopped
            default: break
            }
        }
    }
    
    override init() {
        player = AVPlayer()
        status = RadioPlayerStatus.stopped
        super.init()
        player.addObserver(self, forKeyPath: "rate", options: [.new, .old], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let newValue = change?[NSKeyValueChangeKey(rawValue: "new")] else {
            return
        }
        
        guard keyPath != "timedMetadata" else {
            if let metadata = player.currentItem?.timedMetadata?.first {
                let stationMetadata = StationMetadata(from: metadata)
                playbackDelegate?.updateStationMetadata(with: stationMetadata)
            }
            return
        }
        if status == .playing && newValue as? Int == 0 && keyPath == "rate" {
            status = .stalled
            playbackDelegate?.playbackStalled()
        }
        
        if keyPath == "status" && newValue as? Int == 1 && (status == .paused) {
            play()
            playbackDelegate?.startPlaybackIndicator()
        }
        
        if keyPath == "status" && newValue as? Int == 2 {
            status = .stalled
            playbackDelegate?.playbackStalled()
            stopPlayback()
        }
        
        if keyPath == "rate" && newValue as? Int == 1 && status == .playing {
            playbackDelegate?.startPlaybackIndicator()
        }
    }
    
    func setStation(_ station: RadioStation, shouldStartPlayback startPlayback: Bool = true) {
        currentStation = station
        if startPlayback { status = .paused } else { status = .stopped }
        if status == .playing { status = .paused }
        guard let url = (URL(string: station.url))  else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let stationPlayerItem = AVPlayerItem(url: url)
            DispatchQueue.main.async {
                if self.currentStation! == station {
                    self.player.currentItem?.removeObserver(self, forKeyPath: "status")
                    self.player.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
                    //if we replace repeadetly the item, the player can get stuck in status unknown setting the item to nil first seems to fix it
                    self.player.replaceCurrentItem(with: nil)
                    self.player.replaceCurrentItem(with: stationPlayerItem)
                    self.player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
                    self.player.currentItem?.addObserver(self, forKeyPath: "timedMetadata", options: [.new, .old], context: nil)
                    self.registerBackgroundTask()
                } else {
                    print("ignored request, current station is different")
                }
            }
        }
    }
    
    func resumePlayAfterInterrupt() {
        if let station = currentStation {
            setStation(station)
        }
    }
    
    func isPaused() -> Bool {
        return player.rate == 0
    }
    //rename this method into what it actually does
    private func isPlayBackBufferFull() -> Bool {
        guard let playerItem = player.currentItem else {
            return true
        }
        
        return playerItem.isPlaybackBufferFull || isPreloadedDurationTooLong()
    }
    
    private func isPreloadedDurationTooLong() -> Bool {
        if #available(iOS 10.0, *) {
            return false
        }
        guard let playerItem = player.currentItem else {
            return true
        }
        var timeRangeFull = false
        if let timeRange = playerItem.loadedTimeRanges.first as? CMTimeRange {
            let start = timeRange.start
            let end = timeRange.end
            let duration = CMTimeGetSeconds(CMTimeAdd(start, end))
            timeRangeFull = duration > 45 ? true : false
        }
        
        return timeRangeFull
    }
    
    @available(*, deprecated, message: "call play/pause functions instead")
    func togglePlayback() {
        guard let station = currentStation else { return }
        if status == .stalled || isPlayBackBufferFull() || status == .stopped {
            setStation(station)
            play()
            return
        }
        if isPaused() || status == .stopped {
            play()
        } else {
            pause()
        }
    }
    
    func pause() {
        status = .stopped
        player.pause()
        playbackDelegate?.stopPlaybackIndicator()
    }
    
    func play() {
        guard player.currentItem != nil else {
            resumePlayAfterInterrupt()
            return
        }
        
        guard !isPlayBackBufferFull() else {
            if let station = currentStation { setStation(station) }
            return
        }
        
        status = .playing
        player.play()
    }
	
    func stopPlayback() {
        guard let item = player.currentItem else { return }
        item.cancelPendingSeeks()
        item.asset.cancelLoading()
        item.removeObserver(self, forKeyPath: "status")
        self.player.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
        player.replaceCurrentItem(with: nil)
        player.pause()
    }
    
    private func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    private func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
}
