import Foundation
import AVFoundation

class RadioPlayer {
  private var player: AVPlayer
  private var currentStation: RadioStation?
  
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
  
  func nextStation() {
    
  }
  
  func prevStation() {
    
  }
  
}
