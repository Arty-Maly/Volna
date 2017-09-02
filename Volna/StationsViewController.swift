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
  private var originalIndexPath: IndexPath?
  private var draggingIndexPath: IndexPath?
  private var draggingView: UIView?
  private var dragOffset: CGPoint?
  
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
    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture))
    self.stationCollection?.addGestureRecognizer(longPressGesture)
  }
  
  func handleLongGesture(gesture: UILongPressGestureRecognizer) {
    switch(gesture.state) {
    case UIGestureRecognizerState.began:
      startDragAtLocation(location: gesture.location(in: self.stationCollection), superViewLocation: gesture.location(in: self.stationCollection!.superview))
    case UIGestureRecognizerState.changed:
      updateDragLocation(location: gesture.location(in: gesture.view!), superViewLocation: gesture.location(in: self.stationCollection!.superview))
//      stationCollection?.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
    case UIGestureRecognizerState.ended:
      endDragAtLocation(location: gesture.location(in: self.stationCollection))
//      let cell = stationCollection?.cellForItem(at: selectedIndexPath) as! StationCollectionViewCell
//      cell.hideShadow()
//      stationCollection?.endInteractiveMovement()
    default:
      stationCollection?.cancelInteractiveMovement()
    }
  }
  
  private func endDragAtLocation(location: CGPoint) {
    guard let dragView = draggingView else { return }
    guard let indexPath = draggingIndexPath else { return }
    guard let cv = stationCollection else { return }
//    guard let datasource = cv.dataSource else { return }
    let cell = cv.cellForItem(at: indexPath)
    let targetCenter = cv.convert(cell!.center, to: cv.superview)
    let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
    shadowFade.fromValue = 0.8
    shadowFade.toValue = 0
    shadowFade.duration = 0.4
    dragView.layer.add(shadowFade, forKey: "shadowFade")
    UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
      dragView.center = targetCenter
      dragView.transform = .identity
      
    }) { (completed) in
      cell?.isHidden = false
      dragView.removeFromSuperview()
      self.stationCollection?.collectionViewLayout.invalidateLayout()
    }
    self.draggingIndexPath = nil
    self.draggingView = nil
    saveContext()
  }
  
  private func updateDragLocation(location: CGPoint, superViewLocation: CGPoint) {
    guard let view = draggingView else { return }
    guard let cv = stationCollection else { return }
    let frameHeight = cv.superview!.bounds.size.height
    let frameWidth = cv.superview!.bounds.size.width
  
    let centerX =  superViewLocation.x + dragOffset!.x + view.bounds.size.width/2 <= frameWidth && superViewLocation.x + dragOffset!.x - view.bounds.size.width/2 >= 0 ? superViewLocation.x + dragOffset!.x : view.center.x
    let centerY = superViewLocation.y + dragOffset!.y + view.bounds.size.height/2 <= frameHeight && superViewLocation.y + dragOffset!.y - view.bounds.size.width/2 >= 0 ? superViewLocation.y + dragOffset!.y : view.center.y
    view.center = CGPoint(x: centerX, y: centerY)

    if superViewLocation.y < frameHeight/4 {
      let offset = cv.contentOffset.y > 11 ? 11 : cv.contentOffset.y
      UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
        cv.contentOffset = cv.contentOffset.applying(CGAffineTransform(translationX: 0, y: -offset))
      })
    } else if superViewLocation.y > (1.8 * frameHeight/3) {
      let offset = frameHeight+cv.contentOffset.y + 11 < cv.collectionViewLayout.collectionViewContentSize.height ? 11 : cv.collectionViewLayout.collectionViewContentSize.height - frameHeight-cv.contentOffset.y
      UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
        cv.contentOffset = cv.contentOffset.applying(CGAffineTransform(translationX: 0, y: offset))
      })
    }
    if let newIndexPath = cv.indexPathForItem(at: location) {
      updateStationPositions(source: draggingIndexPath!.row, destination: newIndexPath.row)
      cv.moveItem(at: draggingIndexPath!, to: newIndexPath)
      draggingIndexPath = newIndexPath
    }
    
//    cv.collectionViewLayout.invalidateLayout()
    
  }
  
  private func scrollTo(_ rect: CGRect) {
//    UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
      self.stationCollection?.scrollRectToVisible(rect, animated: true)
//    })
  }
  
  private func startDragAtLocation(location: CGPoint, superViewLocation: CGPoint) {
    guard let cv = stationCollection else { return }
    guard let indexPath = cv.indexPathForItem(at: location) else { return }
//    guard cv.dataSource?.collectionView?(cv, canMoveItemAt: indexPath) == true else { return }
    guard let cell = cv.cellForItem(at: indexPath) else { return }
    
    originalIndexPath = indexPath
    draggingIndexPath = indexPath
    draggingView = cell.snapshotView(afterScreenUpdates: true)
    draggingView!.frame = cv.convert(cell.frame, to: cv.superview)
    cell.isHidden = true
    cv.superview?.addSubview(draggingView!)
    
    dragOffset = CGPoint(x: draggingView!.center.x - superViewLocation.x, y: draggingView!.center.y - superViewLocation.y)

    
    draggingView?.layer.shadowPath = UIBezierPath(rect: draggingView!.bounds).cgPath
    draggingView?.layer.shadowColor = UIColor.black.cgColor
    draggingView?.layer.shadowOpacity = 0.8
    draggingView?.layer.shadowRadius = 10
    
    stationCollection?.collectionViewLayout.invalidateLayout()
    
    UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
      self.draggingView?.alpha = 0.95
      self.draggingView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
    }, completion: nil)
    //      cell.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
//    stationCollection?.beginInteractiveMovementForItem(at: indexPath)
    
  }
  
  private func updateStationPositions(source: Int, destination: Int) {
    let offset = source > destination ? 1 : -1
    let range = createRange(source, destination)
    let station = type == .main ? RadioStation.getStationByPosition(position: source, inManagedContext: managedObjectContext!)
                                 : RadioStation.getFavouriteStationByPosition(position: source, inManagedContext: managedObjectContext!)
    let stations = type == .main ? RadioStation.getStationByPositionInRange(range: range, inManagedContext: managedObjectContext!)
                                  : RadioStation.getStationByFavouritePositionInRange(range: range, inManagedContext: managedObjectContext!)
    for station in stations {
      shiftStationPositionBasedOnType(station, offset: Int16(offset))
    }
    updateSourceStation(station, position: Int16(destination))
  }
  
  private func updateSourceStation(_ station: RadioStation, position: Int16) {
    if type == .main {
      station.position = position
    } else {
      station.favouritePosition = position
    }
  }
  
  private func shiftStationPositionBasedOnType(_ station: RadioStation, offset: Int16) {
    if type == .main {
      station.position += offset
    } else {
      station.favouritePosition! += offset
    }
  }
  
  private func saveContext() {
    do {
      try managedObjectContext?.save()
    } catch let error {
      print(error)
    }
  }
  
  
  private func createRange(_ x: Int, _ y: Int) -> CountableClosedRange<Int> {
    guard x > y else {
      return x...y
    }
    return y...x
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
//    if let image = ImageCache.shared[station.image] {
//      cell.imageView.image = image
//    }
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
      let previousPosition = type == .main ? previousStation.position : previousStation.favouritePosition
      guard let position = previousPosition else {
        return
      }
      let previousCell = stationCollection?.cellForItem(at: IndexPath(row: Int(position), section: 0))
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

