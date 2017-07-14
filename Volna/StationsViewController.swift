import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import GoogleMobileAds

class StationsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, StationCollectionDelegate {
  private var previousIndexPath: IndexPath?
  private var managedObjectContext: NSManagedObjectContext?
  private let numberOfItemsPerRow: Int
  private var currentStation: RadioStation?
  private let reuseIdentifier = "stationCell"
  var type: ViewControllerType?
  @IBOutlet weak var stationCollection: UICollectionView?
  weak var stationViewDelegate: StationViewDelegate?
  weak var stationCollectionDelegate: StationCollectionDelegate?

  required init(coder aDecoder: NSCoder) {
    self.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
    switch UIDevice.current.userInterfaceIdiom {
    case .phone:
      numberOfItemsPerRow = 3
    case .pad:
      numberOfItemsPerRow = 6
    default:
      numberOfItemsPerRow = 3
    }
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return getCellCountForType()
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
    flowLayout.minimumLineSpacing = 3
    flowLayout.minimumInteritemSpacing = 3
    let totalSpace = flowLayout.sectionInset.left
                   + flowLayout.sectionInset.right
                   + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1))
    let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfItemsPerRow))
    return CGSize(width: size, height: size)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! StationCollectionViewCell
    let station =  getStation(indexPathItem: indexPath.item)
    cell.prepareCellForDisplay(station)
    if currentStation == cell.radioStation {
      cell.backgroundColor = Colors.highlightColor
    }
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath) as! StationCollectionViewCell
    stationViewDelegate?.change(station: cell.radioStation)
    clearPreviousCellBackground()
    previousIndexPath = indexPath
    currentStation = cell.radioStation
    cell.backgroundColor = Colors.highlightColor
    stationCollectionDelegate?.stationClicked(clickedStation: cell.radioStation)
  }
  
  private func clearPreviousCellBackground() {
    if let previousStation = currentStation {
      let previousPosition = type == .main ? Int(previousStation.position) : Int(previousStation.favouritePosition!)
      let previousCell = stationCollection?.cellForItem(at: IndexPath(row: previousPosition, section: 0))
      previousCell?.backgroundColor = UIColor.white
    }
  }
  private func getCellCountForType() -> Int {
    switch type! {
    case .main:
      return RadioStation.getStationCount(inManagedContext: managedObjectContext!)
    case .favourite:
      return RadioStation.getFavouritesCount(inManagedContext: managedObjectContext!)
    }
  }
  
  private func getStation(indexPathItem: Int) -> RadioStation {
    switch type! {
    case .main:
      return RadioStation.getStationByPosition(position: (indexPathItem), inManagedContext: managedObjectContext!)
    case .favourite:
      return RadioStation.getFavouriteStationByPosition(position: (indexPathItem), inManagedContext: managedObjectContext!)
    }
  }
  
  func favouriteButtonPressed() {
    previousIndexPath = nil
    stationCollection?.reloadData()
  }
  
  func stationClicked(clickedStation: RadioStation) {
    currentStation = clickedStation
    if let path = stationCollection?.indexPathsForVisibleItems {
      stationCollection?.reloadItems(at: path)
    }
  }
  
  func updateCurrentStation(station: RadioStation) {
  
  }
}

