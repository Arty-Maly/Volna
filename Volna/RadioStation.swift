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
  
  class func saveStation(stationInfo: NSDictionary, inManagedContext context: NSManagedObjectContext) -> Bool {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
    request.predicate = NSPredicate(format: "name = %@", stationInfo["name"] as! String)
    
    if let station = (try? context.fetch(request))?.first as? RadioStation {
      return true
    } else if let station = NSEntityDescription.insertNewObject(forEntityName: "RadioStation", into: context) as? RadioStation{
      print("in else")
      station.name = stationInfo["name"] as! String
      station.url = stationInfo["url"] as! String
//      print(stationInfo["position"]!)
      station.position = Int32(stationInfo["position"] as! Int)
      return true
    }
    
    return true
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
}
