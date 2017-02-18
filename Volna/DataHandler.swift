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
  
  private init() {
    self.managedObjectContext = ((UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext)!
  }
  
  
  func syncRadioStations() {
    let baseUrl = Constants.apiBaseURL
    let uuid = User.getUserUuid(inManagedContext: managedObjectContext)
    let url = URL(string: baseUrl + uuid)!
    let request = RequestMaker(url: url)
    request.getStations { [weak self] (data) -> ()  in self?.matchLocalData(with: data) }
  }
  
  private func matchLocalData(with data: Data) {
    let jsonStations = parse(data: data)
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
    guard let localStations = (try? managedObjectContext.fetch(request)) as? Array<RadioStation>  else {
      print("error retrieving stations")
      exit(0)
    }
    guard localStations.count > 0 else {
      saveStations(jsonStations)
      return
    }
    print(localStations.first!.toHash() == jsonStations.first! )
    
    
  }
  
  private func parse(data: Data) -> Array<[String: String]> {
    let parsedData: Array<[String: String]>
    do {
      let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Array<[String: String]>]
      parsedData = json["stations"]!
    } catch {
      parsedData = []
      print("error parsing json")
    }
    return parsedData
  }
  
  private func saveStations(_ stations: Array<[String: String]>) {
    for station in stations {
      _ = RadioStation.saveStation(stationInfo: station, inManagedContext: managedObjectContext)
    }
  }
}
