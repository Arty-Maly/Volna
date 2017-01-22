import Foundation
import AVFoundation

class RadioPlayer {
  private var player: AVPlayer
  private var currentStation: String?
  
  init() {
    player = AVPlayer()
  }
  
  func setStation(_ stationUrl: String) {
    currentStation = stationUrl
    if let url = (URL( string:stationUrl)) {
      DispatchQueue.global(qos: .userInitiated).async {
        let stationPlayerItem = AVPlayerItem(url: url)
        DispatchQueue.main.async {
          if self.currentStation! == stationUrl {
            self.player.replaceCurrentItem(with: stationPlayerItem)
            if self.isPaused() { self.play() }
          } else {
            print("ignored request, current station is different")
          }
        }
      }
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
  
}
