import UIKit
import AVFoundation
import MediaPlayer
import CoreData

class RadioViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  private var player: RadioPlayer
  private var playImage: UIImage
  private var pauseImage: UIImage

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
        
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print(error)
    }
  }
  @IBAction func playStation() {
    player.play()
    togglePlaybackButton()
  }
  
  private func setStation(stationName: String, stationUrl: String) {
    player.setStation(stationUrl)
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
    setStation(stationName: cell.stationName.text!, stationUrl: cell.stationUrl!)
  }
}

