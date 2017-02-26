//
//  RadioStation+CoreDataClass.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import CoreData

@objc(RadioStation)
public class RadioStation: NSManagedObject {
  
  class func saveStation(stationInfo: [String: String], inManagedContext context: NSManagedObjectContext) -> RadioStation? {
    var radioStation: RadioStation?
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
    request.predicate = NSPredicate(format: "name = %@", stationInfo["name"]!)
    if let station = (try? context.fetch(request))?.first as? RadioStation {
      radioStation = station
    } else if let station = NSEntityDescription.insertNewObject(forEntityName: "RadioStation", into: context) as? RadioStation {
      station.name = stationInfo["name"]!
      station.url = stationInfo["url"]!
      station.position = Int32(stationInfo["position"]!)!
      station.image = stationInfo["image"]!
      radioStation = station
    }
    do {
      try context.save()      
    
    } catch let error {
      print(error)
    }
    return radioStation
  }
  
  class func getStationCount(inManagedContext context: NSManagedObjectContext) -> Int {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
    do {
      let count = try context.count(for: request)
      return count
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      return 0
    }
  }
  
  class func getStationByPosition(position: Int, inManagedContext context: NSManagedObjectContext) -> RadioStation {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
    request.predicate = NSPredicate(format: "position = %ld", position)
    let station = (try? context.fetch(request))?.first as! RadioStation

    return station
  }
  
  func toHash() -> [String: String] {
    let dict =  [ "name": self.name as String,
                  "url" : self.url as String,
                  "position": String(self.position),
                  "image": self.image as String
                ]
    return dict
  }
  
  func update(attributes: [String: String]) {
    self.image = attributes["image"]!
    self.name = attributes["name"]!
    self.position = Int32(attributes["position"]!)!
    self.url = attributes["url"]!
//    do {
//      try self.managedObjectContext?.save()
//    } catch let error {
//      print(error)
//    }
  }
}
