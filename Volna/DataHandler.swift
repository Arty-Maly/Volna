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
    let uuidString = Constants.uuidString
    let countryString = Constants.countryString
    let country = Constants.country
    let uuid = User.getUserUuid(inManagedContext: managedObjectContext)
    let url = URL(string: baseUrl + uuidString + uuid + countryString + country)!
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
      if var jsonStation = jsonStations[station.name] {
        jsonStation.removeValue(forKey: "position")
        if jsonStation == station.toHash() && station.thumbnail != nil {
          jsonStations[station.name] = nil
        }
      } else {
        managedObjectContext.delete(station)
        do {
          try self.managedObjectContext.save()
        } catch {
          fatalError("Failure: \(error)")
        }
      }
    }
    if jsonStations.count > 0 {
      print("count greater than")
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
      let stationManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      stationManagedObjectContext.parent = self.managedObjectContext
      if let radioStation = RadioStation.saveStation(stationInfo: station, inManagedContext: stationManagedObjectContext) {
        DispatchQueue.global(qos: .userInitiated) .async {
          self.prepareImageForSaving(radioStationId: radioStation.objectID)
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
  
  private func saveImage(thumbnailData:NSData, date: Double, radioStationId: NSManagedObjectID) {
    saveQueue.async(group: syncGroup) {
      let imageManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      imageManagedObjectContext.parent = self.managedObjectContext
      let radioStation = imageManagedObjectContext.object(with: radioStationId) as! RadioStation
      let image_url = radioStation.image
      let fetchRequest = NSFetchRequest<Thumbnail>(entityName: "Thumbnail")
      let predicate = NSPredicate(format: "url == %@", image_url)
      fetchRequest.predicate = predicate
      do {
        let fetchResult = try imageManagedObjectContext.fetch(fetchRequest)
        if fetchResult.count > 0 {
          return
        }
      } catch {
        fatalError("Failure: \(error)")
      }
      guard let thumbnail = NSEntityDescription.insertNewObject(forEntityName: "Thumbnail", into: imageManagedObjectContext) as? Thumbnail else {
        print("managedObjectContext error")
        return
      }
      
      thumbnail.imageData = thumbnailData
      thumbnail.id = date as NSNumber
      thumbnail.url = image_url
      thumbnail.radioStation = radioStation
      do {
        try imageManagedObjectContext.save()
      } catch {
        fatalError("Failure to save context: \(error)")
      }
    }
  }
  
  private func prepareImageForSaving(radioStationId: NSManagedObjectID) {
    convertQueue.async(group: syncGroup) {
      let imageManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      imageManagedObjectContext.parent = self.managedObjectContext
      let radioStation = imageManagedObjectContext.object(with: radioStationId) as! RadioStation
      let data = try? Data(contentsOf:  URL(string: radioStation.image)!)
      let image = UIImage(data: data!)!
      let date : Double = NSDate().timeIntervalSince1970
      guard let thumbnailData  = UIImagePNGRepresentation(image) else {
        print("png error")
        return
      }
      self.saveImage(thumbnailData: thumbnailData as NSData, date: date, radioStationId: radioStation.objectID)
    }
    
  }
  
  private func notifyEndOfSync() {
    NotificationCenter.default.post(name: Notification.Name(Constants.endOfSyncNotification), object: nil)
  }
  
  private func deleteAllRadioStations() {
    let appDel = UIApplication.shared.delegate as! AppDelegate
    let context = appDel.managedObjectContext
    
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    do {
      try context.execute(deleteRequest)
    } catch let error as NSError {
      debugPrint(error)
    }
  }
}
