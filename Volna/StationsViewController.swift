import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import GoogleMobileAds

class StationsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, StationCollectionDelegate {
  private var previousIndexPath: IndexPath?
  private var managedObjectContext: NSManagedObjectContext?
  private let numberOfItemsPerRow: Int
  private let reuseIdentifier = "stationCell"
  var type: ViewControllerType?
  @IBOutlet weak var stationCollection: UICollectionView!
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
    let station =  getStation(indexPathItem: indexPath.item)
    cell.prepareCellForDisplay(station)
    if indexPath == previousIndexPath {
      cell.backgroundColor = Colors.highlightColor
    }
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath) as! StationCollectionViewCell
    stationViewDelegate?.change(station: cell.radioStation)
    if let previousPosition = previousIndexPath {
      let previousCell = collectionView.cellForItem(at: previousPosition)
      previousCell?.backgroundColor = UIColor.clear
    }
    previousIndexPath = indexPath
    cell.backgroundColor = Colors.highlightColor
    stationCollectionDelegate?.stationClicked(clickedStation: cell.radioStation)
  }
  
  private func getCellCountForType() -> Int {
    switch type! {
    case .main:
      return RadioStation.getStationCount(inManagedContext: managedObjectContext!)
    case .favourite:
      return RadioStation.getFavourites(inManagedContext: managedObjectContext!)
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
    stationCollection.reloadData()
  }
  
  func stationClicked(clickedStation: RadioStation) {
    switch type! {
    case .main:
      previousIndexPath = IndexPath(item: Int(clickedStation.position), section: 0)
    case .favourite:
      if let position = RadioStation.getFavouriteStationPosition(station: clickedStation, inManagedContext: managedObjectContext!) {
        previousIndexPath = IndexPath(item: position, section: 0)
      } else {
        previousIndexPath = nil
      }
    }
    if let path = stationCollection?.indexPathsForVisibleItems {
      stationCollection?.reloadItems(at: path)
    }
  }
}

