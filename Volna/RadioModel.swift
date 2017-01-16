import Foundation
import AVFoundation

class RadioModel {
  private var player: AVPlayer
  private var radioStations: Dictionary<String,String>
  private var currentStation: String?
  
  init() {
    player = AVPlayer()
    radioStations = [
      "Echo FM" : "http://78.110.61.92:8000/echo",
      "Business FM" : "http://78.110.61.92:8000/bfm96",
      "Relax FM" : "http://stream01.media.rambler.ru:80/relax128.mp3",
      "Руссое Радио" : "http://78.110.61.92:8000/rr96",
      "Record" : "http://78.110.61.92:8000/record128",
      "Дача" : "http://78.110.61.92:8000/dacha",
      "Наше" : "http://78.110.61.92:8000/nashe128",
      "Dfm" : "http://78.110.61.92:8000/dfm",
      "Ultra" : "http://78.110.61.92:8000/ultra128",
      "Best FM" : "http://78.110.61.92:8000/best128",
      "Шансон" : "http://78.110.61.92:8000/chanson128",
      "Зенит" : "http://78.110.61.92:8000/zenit128",
      "Эльдорадио" : "http://78.110.61.92:8000/eldoradio128",
      "L Radio" : "http://78.110.61.92:8000/lradio96",
      "Кекс" : "http://78.110.61.92:8000/keks128",
      "Радио Спорт" : "http://78.110.61.92:8000/sport128",
      "Пионер" : "http://78.110.61.92:8000/pioner128",
      "Джаз" : "http://78.110.61.92:8000/jazz128",
      "Юнитон" : "http://78.110.61.92:8000/uniton128",
      "Орфей" : "http://78.110.61.92:8000/orpheus128",
      "Шоколад" : "http://78.110.61.92:8000/chocolate128",
      "Говорит Москва" : "http://78.110.61.92:8000/govoritmoskva96",
      "Русский Хит" : "http://78.110.61.92:8000/rushit48",
      "Comedy" : "http://78.110.61.92:8000/comedy",
      "Rock FM" : "http://78.110.61.92:8000/rock128",
      "Звезда" : "http://78.110.61.92:8000/zvezda128",
      "АвтоРадио" : "http://78.110.61.92:8000/avtoradio",
      "Радио России" : "http://78.110.61.92:8000/radiorosii128",
      "Радио Свобода" : "http://78.110.61.92:8000/svoboda",
      "Юмор" : "http://78.110.61.92:8000/humor256",
      "NRJ" : "http://78.110.61.92:8000/nrj256",
      "МСМ Иркутск" : "http://78.110.61.92:8000/mcm128",
      "Милицейская Волна" : "http://78.110.61.92:8000/mvd128",
      "Комсомольская Правда" : "http://78.110.61.92:8000",
      "Город" : "http://78.110.61.92:8000/gorodfm128",
      "Романтика" : "http://78.110.61.92:8000/romantika256",
      "Мегаполис" : "http://78.110.61.92:8000/megapolis128",
      "Радио ОК" : "http://78.110.61.92:8000/okradio128",
      "Alex-M" : "http://78.110.61.92:8000/alexm320",
      "Большое Радио" : "http://78.110.61.92:8000/bolshoe128",
      "Радио 107" : "http://78.110.61.92:8000/radio107_128",
      "Борнео" : "http://78.110.61.92:8000/borneo128",
      "Курс" : "http://78.110.61.92:8000/kurs",
      "Коммерсант" : "http://78.110.61.92:8000/kommersant128",
      "Рус Новости" : "http://78.110.61.92:8000/rsn"
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
  
  
  func getStationNameByPosition(position: Int) -> String {
    return radioStations.keys.sorted()[position]
  }
  
  func numberOfStations() -> Int {
    return radioStations.count
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
