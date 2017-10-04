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
        
        mutating func toggleStatus() {
            switch self {
            case .playing: self = .paused
            case .paused: self = .playing
            default: break
            }
        }
    }
    
    override init() {
        player = AVPlayer()
        status = RadioPlayerStatus.paused
        super.init()
        player.addObserver(self, forKeyPath: "rate", options: [.new, .old], context: nil)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let newValue = change?[NSKeyValueChangeKey(rawValue: "new")] else {
            return
        }
        
        if status == .playing && newValue as? Int == 0 && keyPath == "rate" {
            status = .stalled
            playbackDelegate?.playbackStalled()
        }
        
        if keyPath == "status" && newValue as? Int == 1 && status == .preparing {
            playbackDelegate?.startPlaybackIndicator()
            play()
        }
    }
    
    func setStation(_ station: RadioStation, shouldStartPlayback startPlayback: Bool = true) {
        currentStation = station
        if startPlayback { status = .preparing }
        guard let url = (URL(string: station.url))  else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let stationPlayerItem = AVPlayerItem(url: url)
            DispatchQueue.main.async {
                if self.currentStation! == station {
                    self.player.currentItem?.removeObserver(self, forKeyPath: "status")
                    self.player.replaceCurrentItem(with: stationPlayerItem)
                    self.player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
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
    private func isPlayBackBufferFull() -> Bool {
        guard let playerItem = player.currentItem else {
            return false
        }
        return playerItem.isPlaybackBufferFull
    }
    
    func togglePlayback() {
        guard let station = currentStation else { return }
        guard status != .stalled || !isPlayBackBufferFull() || status != .stopped else {
            setStation(station)
            play()
            return
        }
        if isPaused() {
            status = .playing
            play()
        } else {
            status = .paused
            player.pause()
        }
    }
    
    func pause() {
        player.pause()
    }
    
    func play() {
        player.play()
    }
	
    func stopPlayback() {
        guard let item = player.currentItem else { return }
        item.cancelPendingSeeks()
        item.asset.cancelLoading()
        player.replaceCurrentItem(with: nil)
        status = .stopped
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
