import Foundation
import AVFoundation

class RadioModel {
  private var player: AVPlayer
  private var radioStations: Dictionary<String,String>
  private var currentStation: String?
  
  init() {
    player = AVPlayer()
    radioStations = [
      "Echo FM" : "http://stream05.media.rambler.ru/echo.mp3",
      "Business FM" : "www",
      "Relax FM" : "http://stream01.media.rambler.ru:80/relax128.mp3"
      
    ]
  }
  
  func setStation(_ station: String) {
    if radioStations.keys.contains(station) {
      currentStation = station
      DispatchQueue.global(qos: .userInitiated).async {
        let stationPlayerItem = AVPlayerItem( url:URL( string:self.radioStations[station]!)!)
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
  
  private func isPaused() -> Bool {
    return player.rate == 0
  }
  private func isPlayBackBufferFull() -> Bool {
    return player.currentItem!.isPlaybackBufferFull
  }
  func play() {
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
