import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import GoogleMobileAds

class StationsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, StationCollectionDelegate, UISearchBarDelegate {
    private var previousIndexPath: IndexPath?
    private var searchActive: Bool
    private var keyboardActive: Bool?
    private var searchText: String?
    private var managedObjectContext: NSManagedObjectContext?
    private var numberOfItemsPerRow: CGFloat {
        get {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return CGFloat(3)
            case .pad:
                guard UIApplication.shared.statusBarOrientation.isPortrait else { return CGFloat(6) }
                return CGFloat(5)
            default:
                return CGFloat(3)
            }
        }
    }
    private var currentStation: RadioStation?
    private let reuseIdentifier = "stationCell"
    private var originalIndexPath: IndexPath?
    private var draggingIndexPath: IndexPath?
    private var draggingView: UIView?
    private var dragOffset: CGPoint?
    private var section = 1
    private var viewSize: CGSize?
    
    var type: ViewControllerType? {
        didSet {
            if type == .main {
                section = 1
            } else {
                section = 0
            }
            
        }
    }
    @IBOutlet weak var stationCollection: UICollectionView?
    weak var stationViewDelegate: StationViewDelegate?
    weak var stationCollectionDelegate: StationCollectionDelegate?
    
    required init(coder aDecoder: NSCoder) {
        self.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
        searchActive = false
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture))
        self.stationCollection?.addGestureRecognizer(longPressGesture)
        addObservers()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard type == .main else { return 1 }
        return 2
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchActive = false
            if let text = self.searchText, text.count > 1 {
                //dissmiss keyboard if we cleared the whole sentence, wait until searchbar becomes first responder a littl bit hacky but no delegate method for the x button tapped
                searchBar.perform(#selector(self.resignFirstResponder), with: nil, afterDelay: 0.1)
            }
        } else {
            searchActive = true
        }
        self.searchText = searchText
        self.stationCollection?.reloadSections([1])
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        guard let searchTextEmpty  = searchBar.text?.isEmpty else { return }
        if searchTextEmpty {
            searchActive = false
        }
        self.stationCollection?.reloadSections([1])
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveState),
            name: NSNotification.Name.UIApplicationWillResignActive,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillAppear),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDisappeared),
            name: NSNotification.Name.UIKeyboardDidHide,
            object: nil)
    }
    
    @objc private func keyboardWillAppear() {
        keyboardActive = true
    }
    
    @objc private func keyboardDisappeared() {
        keyboardActive = false
    }
    
    @objc private func saveState() {
        draggingView?.removeFromSuperview()
        stationCollection?.collectionViewLayout.invalidateLayout()
        if let indexPath = draggingIndexPath {
            let cell = stationCollection?.cellForItem(at: indexPath)
            cell?.isHidden = false
        }
        saveContext()
    }
    
    
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case UIGestureRecognizerState.began:
            startDragAtLocation(location: gesture.location(in: self.stationCollection), superViewLocation: gesture.location(in: self.stationCollection!.superview))
        case UIGestureRecognizerState.changed:
            updateDragLocation(location: gesture.location(in: gesture.view!), superViewLocation: gesture.location(in: self.stationCollection!.superview))
        case UIGestureRecognizerState.ended:
            endDragAtLocation(location: gesture.location(in: self.stationCollection))
        default:
            stationCollection?.cancelInteractiveMovement()
        }
    }
    
    private func endDragAtLocation(location: CGPoint) {
        guard let dragView = draggingView else { return }
        guard let indexPath = draggingIndexPath else { return }
        guard let cv = stationCollection else { return }
        //    guard let datasource = cv.dataSource else { return }
        if let cell = cv.cellForItem(at: indexPath) {
            let targetCenter = cv.convert(cell.center, to: cv.superview)
            let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
            shadowFade.fromValue = 0.8
            shadowFade.toValue = 0
            shadowFade.duration = 0.4
            dragView.layer.add(shadowFade, forKey: "shadowFade")
            UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
                dragView.center = targetCenter
                dragView.transform = .identity
                
            }) { (completed) in
                cell.isHidden = false
                dragView.removeFromSuperview()
                self.stationCollection?.collectionViewLayout.invalidateLayout()
            }
        
            self.draggingIndexPath = nil
            self.draggingView?.removeFromSuperview()
            self.draggingView = nil
            
            saveContext()
        }
    }
    
    private func updateDragLocation(location: CGPoint, superViewLocation: CGPoint) {
        guard let view = draggingView else { return }
        guard let cv = stationCollection else { return }
        guard let dragIndexPath = draggingIndexPath else {return}
        if let cell = cv.cellForItem(at: dragIndexPath), !cell.isHidden  { cell.isHidden = true }
        let viewWidth = view.bounds.size.width
        let frameHeight = cv.superview!.bounds.size.height
        let frameWidth = cv.superview!.bounds.size.width
        let fullScrollHeight = cv.contentSize.height
        let contentOffsetY = cv.contentOffset.y
        
        let centerX =  superViewLocation.x + dragOffset!.x + viewWidth / 2 <= frameWidth && superViewLocation.x + dragOffset!.x - viewWidth / 2 >= 0 ? superViewLocation.x + dragOffset!.x : view.center.x
        let centerY = superViewLocation.y + dragOffset!.y + view.bounds.size.height/2 <= frameHeight && superViewLocation.y + dragOffset!.y - viewWidth/2 >= 0 ? superViewLocation.y + dragOffset!.y : view.center.y
        view.center = CGPoint(x: centerX, y: centerY)
        
        if superViewLocation.y < frameHeight/4 {
            let offset = contentOffsetY > 11 ? 11 : contentOffsetY
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
                cv.contentOffset = cv.contentOffset.applying(CGAffineTransform(translationX: 0, y: -offset))
            })
        } else if superViewLocation.y > (1.8 * frameHeight/3) && fullScrollHeight > frameHeight {
            let offset = frameHeight + contentOffsetY + 11 < fullScrollHeight ? 11 : fullScrollHeight - frameHeight - contentOffsetY
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
                cv.contentOffset = cv.contentOffset.applying(CGAffineTransform(translationX: 0, y: offset))
            })
        }
        if let newIndexPath = cv.indexPathForItem(at: location) {
            updateStationPositions(source: dragIndexPath.row, destination: newIndexPath.row)
            cv.moveItem(at: dragIndexPath, to: newIndexPath)
            draggingIndexPath = newIndexPath
        }
    }
    
    private func startDragAtLocation(location: CGPoint, superViewLocation: CGPoint) {
        guard !searchActive else { return }
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section == 0, type == .main  else { return CGSize.zero }
        
        return CGSize.init(width: (self.stationCollection?.bounds.size.width)!, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard section == 0, type == .main else { return UIEdgeInsets.init(top: 0, left: 0, bottom: 80, right: 0) }
    
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard type == .main else { return RadioStation.getFavouritesCount(inManagedContext: managedObjectContext!) }
        guard section == 1 else { return 0 }
        guard !searchActive else { return getCellCountForSearch() }
        
        return RadioStation.getStationCount(inManagedContext: managedObjectContext!)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = viewSize?.width ?? collectionView.frame.width
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.minimumLineSpacing = 3
        flowLayout.minimumInteritemSpacing = 3
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * numberOfItemsPerRow)
        let size = Int((width - totalSpace) / numberOfItemsPerRow)
        return CGSize(width: size, height: size)
    }
    
    func setTransitionViewSize(_ size: CGSize) {
        viewSize = size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! StationCollectionViewCell
        let station =  getStation(indexPathItem: indexPath.item)
        cell.prepareCellForDisplay(station)
        if currentStation == cell.radioStation {
            previousIndexPath = indexPath
            cell.backgroundColor = Colors.highlightColor
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard keyboardActive != true else { return }
        let cell = collectionView.cellForItem(at: indexPath) as! StationCollectionViewCell
        stationViewDelegate?.change(station: cell.radioStation)
        clearPreviousCellBackground()
        previousIndexPath = indexPath
        currentStation = cell.radioStation
        cell.backgroundColor = Colors.highlightColor
        stationCollectionDelegate?.stationClicked(clickedStation: cell.radioStation)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.white
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if (kind == UICollectionElementKindSectionHeader) {
            let headerView:UICollectionReusableView =  collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "ReuseSearchBar", for: indexPath)
            
            return headerView
        }
        return UICollectionReusableView()
    }
    
    private func clearPreviousCellBackground() {
        guard let indexPath = previousIndexPath else { return }
        
        let previousCell = stationCollection?.cellForItem(at: indexPath)
        previousCell?.backgroundColor = UIColor.white
    }
    
    private func getCellCountForSearch() -> Int {
        guard let text = searchText else { return 0 }

        return RadioStation.getStationCountBySearchText(inManagedContext: managedObjectContext!, searchText: text)
    }
    
    private func getStation(indexPathItem: Int) -> RadioStation {
        guard !searchActive else { return RadioStation.getStationsBySearchText(inManagedContext: managedObjectContext!, searchText: searchText!)[indexPathItem] }
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
    
    func updateCurrentStation(station: RadioStation) {}
}

