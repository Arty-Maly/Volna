import Foundation
import AVFoundation
import UIKit

class RadioPlayer {
  private(set) var player: AVPlayer
  private(set) var currentStation: RadioStation?
  private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
  init() {
    player = AVPlayer()
  }
  
  func setStation(_ station: RadioStation) {
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
    } else {
      return false
    }
  }
  
  func play() {
    if let station = currentStation {
      if isPaused() {
        player.play()
      } else {
        player.pause()
      }
      if isPlayBackBufferFull() {
        setStation(station)
      }
    } else {
      return
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
