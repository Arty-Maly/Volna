//
//  SplashViewController.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
import CoreData

class SplashViewController: UIViewController {
  var managedObjectContext: NSManagedObjectContext?
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    self.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext

  }
  
  override func viewDidAppear(_ animated: Bool) {
    let url = NSURL(string: "")
    let task = URLSession.shared.dataTask(with: url! as URL) {[weak self] (data, response, error) in
      if let stations = self?.parseResponse(data: data!) {
        print("in update")
        self?.updateDatabase(stations as! Array<NSDictionary>)
      }
      DispatchQueue.main.async(){
//        self?.printDatabaseStat()
        self?.performSegue(withIdentifier: "transitionToRadio", sender:nil)
      }
    }
    task.resume()
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func parseResponse(data: Data) -> Array<Any>{
    let parsedData: Array<NSDictionary>
    do {
      let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Array<NSDictionary>]
      parsedData = json["stations"]!
    } catch {
      parsedData = []
      print("error parsing json")
    }
    return parsedData
  }
  
  private func updateDatabase(_ stations: Array<NSDictionary>) {
    managedObjectContext?.perform {
      for station in stations {
        _ = RadioStation.saveStation(stationInfo: station, inManagedContext: self.managedObjectContext!)
      }
      do {
        try self.managedObjectContext?.save()
      } catch let error {
        print(error)
      }
    }
  }
  
  private func printDatabaseStat() {
    managedObjectContext?.perform {
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
      request.predicate = NSPredicate(format: "name = %@", "NRJ")

      if let results = try? self.managedObjectContext!.fetch(request) {
        let a = results.first as! RadioStation
        print(a.url)
      }
      
    }
  }
}
