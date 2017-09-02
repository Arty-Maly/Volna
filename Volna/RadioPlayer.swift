import Foundation
import AVFoundation
import UIKit

class RadioPlayer: NSObject{
  private(set) var player: AVPlayer
  private(set) var currentStation: RadioStation?
  private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
  private var status: RadioPlayerStatus
  var playbackDelegate: PlaybackDelegate?
  
  private enum RadioPlayerStatus {
    case playing
    case paused
    case stalled
    
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
    
    if status == .playing && newValue as? Int == 0 {
      status = .stalled
      playbackDelegate?.playbackStalled()
    }
  }
  
  func setStation(_ station: RadioStation) {
    status = .playing
    currentStation = station
    if let url = (URL( string:station.url)) {
      DispatchQueue.global(qos: .userInitiated).async {
        let stationPlayerItem = AVPlayerItem(url: url)
        DispatchQueue.main.async {
          if self.currentStation! == station {
            self.player.replaceCurrentItem(with: stationPlayerItem)
            self.player.play()
            self.registerBackgroundTask()
          } else {
            print("ignored request, current station is different")
          }
        }
      }
    }
  }
  
  func resumePlayAfterInterrupt() {
    if currentStation != nil {
      setStation(currentStation!)
    }
  }

  func isPaused() -> Bool {
    return player.rate == 0
  }
  private func isPlayBackBufferFull() -> Bool {
    if let playerItem = player.currentItem {
      return playerItem.isPlaybackBufferFull
    }
    return false
  }
  
  func play() {
    guard let station = currentStation else {
      return
    }
    guard status != .stalled && !isPlayBackBufferFull() else {
      setStation(station)
      return
    }
    if isPaused() {
      status = .playing
      player.play()
    } else {
      status = .paused
      player.pause()
    }
  }
  
  func pause() {
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
