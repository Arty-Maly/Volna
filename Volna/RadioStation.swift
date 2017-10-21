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
            station.position = Int16(stationInfo["position"]!)!
            radioStation = station
        }
        radioStation?.name = stationInfo["name"]!
        radioStation?.url = stationInfo["url"]!
        radioStation?.image = stationInfo["image"]!
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
        guard let station = (try? context.fetch(request))?.first else { return findMissingStation(context, missingPosition: position, predicate: "position") }
        return station as! RadioStation
    }
    
    private class func findMissingStation(_ context: NSManagedObjectContext, missingPosition position: Int, predicate: String) -> RadioStation {
        print("yes")
        Logger.logDuplicatStationsHappened(position, predicate: predicate)
        var positions: [Int16]
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
        guard let localStations = (try? context.fetch(request)) as? Array<RadioStation>  else {
            print("error retrieving stations")
            fatalError("error retrieving stations")
        }
        if predicate == "position" {
            positions = localStations.map { return $0.position }
        } else {
            positions = localStations.map { return $0.favouritePosition! }
        }
        
        let duplicates = Array(Set(positions.filter({ i in positions.filter({ $0 == i }).count > 1})))
        guard duplicates.count > 0, let duplicate = duplicates.first else {
            Logger.logCouldNotFindDuplicates(position, array: duplicates, predicate: predicate)
            fatalError()
        }
        request.predicate = NSPredicate(format: "\(predicate) = %ld", duplicate)
        let station = (try? context.fetch(request))?.last as! RadioStation
        station.position = Int16(position)
        do {
            try context.save()
        } catch let error {
            fatalError("error saving missing station \(error)")
        }
        return station
    }
    
    class func getStationByFavouritePositionInRange(range: CountableClosedRange<Int>, inManagedContext context: NSManagedObjectContext) -> [RadioStation] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
        request.predicate = NSPredicate(format: "favouritePosition >= %ld AND favouritePosition <= %ld", range.lowerBound, range.upperBound)
        let stations = (try? context.fetch(request)) as! [RadioStation]
        
        return stations
    }
    
    
    class func getStationByPositionInRange(range: CountableClosedRange<Int>, inManagedContext context: NSManagedObjectContext) -> [RadioStation] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
        request.predicate = NSPredicate(format: "position >= %ld AND position <= %ld", range.lowerBound, range.upperBound)
        let stations = (try? context.fetch(request)) as! [RadioStation]
        
        return stations
    }
    
    func toHash() -> [String: String] {
        let dict =  [ "name": self.name as String,
                      "url" : self.url as String,
                      "image": self.image as String
        ]
        return dict
    }
    
    class func getFavouritesCount(inManagedContext context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
        request.predicate = NSPredicate(format: "favourite == %@", NSNumber(value: true))
        do {
            let count = try context.count(for: request)
            return count
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            return 0
        }
    }
    class func getFavouriteStationByPosition(position: Int, inManagedContext: NSManagedObjectContext) -> RadioStation {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
        request.predicate = NSPredicate(format: "favouritePosition = %ld", position)
        guard let station = (try? inManagedContext.fetch(request))?.first else { return findMissingStation(inManagedContext, missingPosition: position, predicate: "favouritePosition") }
        
        return station as! RadioStation
    }
    
    func toggleFavourite(context: NSManagedObjectContext) {
        if self.favourite {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
            request.predicate = NSPredicate(format: "favouritePosition > %ld", self.favouritePosition!)
            let stations = (try? context.fetch(request)) as! [RadioStation]
            for station in stations {
                station.favouritePosition = station.favouritePosition! - 1
            }
            self.favouritePosition = nil
        } else {
            self.favouritePosition = Int16(RadioStation.getFavouritesCount(inManagedContext: context))
        }
        self.favourite = !self.favourite
        do {
            try context.save()
            
        } catch let error {
            print(error)
        }
    }
    
    func update(attributes: [String: String]) {
        self.image = attributes["image"]!
        self.name = attributes["name"]!
        self.position = Int16(attributes["position"]!)!
        self.url = attributes["url"]!
    }
}
