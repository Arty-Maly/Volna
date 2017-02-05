import UIKit
import AVFoundation
import MediaPlayer
import CoreData

class RadioViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  private var player: RadioPlayer
  private var playImage: UIImage
  private var pauseImage: UIImage
  private var previousCell: StationCollectionViewCell?
  private var currentStationPosition: Int?
  private let infoCenter: MPNowPlayingInfoCenter

  private let numberOfItemsPerRow: Int
  private var managedObjectContext: NSManagedObjectContext?
  @IBOutlet weak var stationTitle: UILabel!
  @IBOutlet weak var playButton: UIButton!
  private let reuseIdentifier = "stationCell"
  @IBOutlet weak var stationCollection: UICollectionView!
  
  required init(coder aDecoder: NSCoder) {
    numberOfItemsPerRow = 3
    player = RadioPlayer()
    playImage = UIImage(named: "play_button.png")!
    pauseImage = UIImage(named: "pause_button.png")!
    infoCenter = MPNowPlayingInfoCenter.default()
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
    setRemoteCommandCenter()
    setAvAudioSession()
      }
  
  private func setAvAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print(error)
    }
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
    player.play()
    togglePlaybackButton()
  }
  
  @objc private func nextStation() {
    let nextPosition = calcNextPosition(1)
    let station = RadioStation.getStationByPosition(position: nextPosition, inManagedContext: managedObjectContext!)
    setStation(stationName: station.name!, stationUrl: station.url!, position: nextPosition)
  }
  
  @objc private func prevStation() {
    let nextPosition = calcNextPosition(-1)
    let station = RadioStation.getStationByPosition(position: nextPosition, inManagedContext: managedObjectContext!)
    setStation(stationName: station.name!, stationUrl: station.url!, position: nextPosition)
  }
  
  private func calcNextPosition(_ increment: Int) -> Int {
    var  nextPosition = currentStationPosition! + increment
    let stationCount = RadioStation.getStationCount(inManagedContext: managedObjectContext!)
    if nextPosition > stationCount {
      nextPosition = 0
    } else if nextPosition < 0 {
      nextPosition = stationCount - 1
    }
    return nextPosition
  }
  
  private func setStation(stationName: String, stationUrl: String, position: Int) {
    player.setStation(stationUrl)
    currentStationPosition = position
    stationTitle.text = stationName
    togglePauseButton()
  }
  
  private func togglePlayButton() {
    playButton.setImage(playImage, for: .normal)
  }
  
  private func togglePauseButton() {
    playButton.setImage(pauseImage, for: .normal)
  }
  
  private func togglePlaybackButton() {
    if player.isPaused() {
      togglePlayButton()
    } else {
      togglePauseButton()
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return RadioStation.getStationCount(inManagedContext: managedObjectContext!)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
    flowLayout.minimumLineSpacing = 10
    flowLayout.minimumInteritemSpacing = 10
    let totalSpace = flowLayout.sectionInset.left
                   + flowLayout.sectionInset.right
                   + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1))
    let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfItemsPerRow))
    return CGSize(width: size, height: size)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! StationCollectionViewCell
    let station = RadioStation.getStationByPosition(position: (indexPath.item), inManagedContext: managedObjectContext!)
    cell.prepareCellForDisplay(station)
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath) as! StationCollectionViewCell
    setStation(stationName: cell.stationName.text!, stationUrl: cell.stationUrl!, position: indexPath.item)
    let albumArtWork = MPMediaItemArtwork(image: cell.imageView.image!)
    infoCenter.nowPlayingInfo = [
      MPMediaItemPropertyArtwork:albumArtWork
    ]
  }
  func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath) as! StationCollectionViewCell
    previousCell?.backgroundColor = UIColor.clear
    cell.backgroundColor = UIColor(red:0.84, green:0.86, blue:0.88, alpha:0.85)
    previousCell = cell
  }
}

