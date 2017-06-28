//
//  DataHandler.swift
//  Volna
//
//  Created by Artem Malyshev on 2/18/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit
import CoreData
import Foundation

class DataHandler {
  static let shared = DataHandler()
  private let managedObjectContext: NSManagedObjectContext
  private let convertQueue: DispatchQueue
  private let saveQueue: DispatchQueue
  private let syncGroup: DispatchGroup

  private init() {
    managedObjectContext = ((UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext)!
    convertQueue = DispatchQueue(label: "convertQueue", attributes: .concurrent)
    saveQueue = DispatchQueue(label: "saveQueue", attributes: .concurrent)
    syncGroup = DispatchGroup()
  }
  
  
  func syncRadioStations() {
    let baseUrl = Constants.apiBaseURL
    let uuid = User.getUserUuid(inManagedContext: managedObjectContext)
    let url = URL(string: baseUrl + uuid)!
    let request = RequestMaker(url: url)
    request.getStations { [weak self] (data) -> ()  in self?.matchLocalData(with: data) }
  }
  
  private func matchLocalData(with data: Data) {
    var jsonStations = parse(data: data)
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
    guard let localStations = (try? managedObjectContext.fetch(request)) as? Array<RadioStation>  else {
      print("error retrieving stations")
      exit(0)
    }
    guard localStations.count > 0 else {
      saveStations(Array(jsonStations.values))
      return
    }
    for station in localStations {
      if let jsonStation = jsonStations[station.name] {
        if jsonStation != station.toHash() {
          station.update(attributes: jsonStation)
        }
        jsonStations[station.name] = nil
      } else {
        managedObjectContext.delete(station)
      }
    }
    if jsonStations.count > 0 {
      saveStations(Array(jsonStations.values))
    } else {
      notifyEndOfSync()
    }
  }
  
  private func parse(data: Data) -> [String:[String:String]] {
    do {
      let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:[String:String]]
      return json
    } catch {
      print("error parsing json")
      return [:]
    }
  }
  
  private func saveStations(_ stations: Array<[String: String]>) {
    for station in stations {
      let imageManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      let stationManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      imageManagedObjectContext.parent = self.managedObjectContext
      stationManagedObjectContext.parent = imageManagedObjectContext
      if let radioStation = RadioStation.saveStation(stationInfo: station, inManagedContext: stationManagedObjectContext) {
        DispatchQueue.global(qos: .userInitiated) .async { [weak self] in
          self?.prepareImageForSaving(radioStationId: radioStation.objectID, inManagedContext: imageManagedObjectContext)
        }
      }
    }
    syncGroup.notify(queue: DispatchQueue.main) {
      do {
        try self.managedObjectContext.save()
        self.notifyEndOfSync()
      } catch {
        fatalError("Failure: \(error)")
      }
    }
  }
  
  private func saveImage(imageData:NSData, thumbnailData:NSData, date: Double, radioStationId: NSManagedObjectID, privateManagedObjectContext: NSManagedObjectContext) {
    saveQueue.async(group: syncGroup) {
      let radioStation = privateManagedObjectContext.object(with: radioStationId) as! RadioStation
      let image_url = radioStation.image
      let fetchRequest = NSFetchRequest<Thumbnail>(entityName: "Thumbnail")
      let predicate = NSPredicate(format: "url == %@", image_url)
      fetchRequest.predicate = predicate
      do {
        let fetchResult = try privateManagedObjectContext.fetch(fetchRequest)
        if fetchResult.count > 0 {
          return
        }
      } catch {
        fatalError("Failure: \(error)")
      }
      guard let fullRes = NSEntityDescription.insertNewObject(forEntityName: "FullResImage", into: privateManagedObjectContext) as? FullResImage, let thumbnail = NSEntityDescription.insertNewObject(forEntityName: "Thumbnail", into: privateManagedObjectContext) as? Thumbnail else {
        print("managedObjectContext error")
        return
      }
      
      fullRes.imageData = imageData
      thumbnail.imageData = thumbnailData
      thumbnail.id = date as NSNumber
      thumbnail.url = image_url
      thumbnail.fullResImage = fullRes
      thumbnail.radioStation = radioStation
      do {
        try privateManagedObjectContext.save()
      } catch {
        fatalError("Failure to save context: \(error)")
      }
    }
  }
  
  private func prepareImageForSaving(radioStationId: NSManagedObjectID, inManagedContext: NSManagedObjectContext) {
    convertQueue.async(group: syncGroup) {
      let radioStation = inManagedContext.object(with: radioStationId) as! RadioStation
      let data = try? Data(contentsOf:  URL(string: radioStation.image)!)
      let image = UIImage(data: data!)!
      let date : Double = NSDate().timeIntervalSince1970
      guard let imageData = UIImagePNGRepresentation(image) else {
        print("png error")
        return
      }
      
      let thumbnail = image.resizeImage(newWidth: CGFloat(90))
      guard let thumbnailData  = UIImagePNGRepresentation(thumbnail) else {
        print("png error")
        return
      }
      self.saveImage(imageData: imageData as NSData, thumbnailData: thumbnailData as NSData, date: date, radioStationId: radioStation.objectID, privateManagedObjectContext: inManagedContext)
    }
    
  }
  
  private func notifyEndOfSync() {
    NotificationCenter.default.post(name: Notification.Name(Constants.myNotificationKey), object: nil)
  }
}
