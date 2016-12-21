import Foundation
import AVFoundation

class RadioModel {
  private var player: AVPlayer
  private var radioStations: Dictionary<String,String>
  private var currentStation: String?
  
  init() {
    player = AVPlayer()
    radioStations = [
      "Relax FM" : "http://stream01.media.rambler.ru:80/relax128.mp3",
      ]
  }
  
  func setStation(_ station: String) {
    if let stationAddress = self.radioStations[station] {
      currentStation = station
      DispatchQueue.global(qos: .userInitiated).async {
        if let stationUrl = (URL( string:stationAddress)) {
          let stationPlayerItem = AVPlayerItem(url:stationUrl)
          DispatchQueue.main.async {
            if self.currentStation! == station {
              self.player.replaceCurrentItem(with: stationPlayerItem)
              if self.isPaused() { self.play() }
            } else {
              print("ignored request, current station is different")
            }
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
    if currentStation == nil {
      return
    }
    if isPaused() {
      player.play()
    } else {
      player.pause()
    }
    if isPlayBackBufferFull() {
      setStation(currentStation!)
    }
  }
  
}
