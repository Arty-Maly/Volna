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
  let imagePicker = UIImagePickerController()
  let convertQueue = DispatchQueue(label: "convertQueue", attributes: .concurrent)
  let saveQueue = DispatchQueue(label: "saveQueue", attributes: .concurrent)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    self.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext
//    imagePickerSetup()
//    coreDataSetup()
    

  }
  
  override func viewDidAppear(_ animated: Bool) {
    getListOfRadioStations()
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
        if let model = RadioStation.saveStation(stationInfo: station, inManagedContext: self.managedObjectContext!) {
          let data = try? Data(contentsOf:  URL(string: model.image!)!)
          let image = UIImage(data: data!)!
          self.prepareImageForSaving(image: image, url: model.image!)
        }
        
      }
      do {
        try self.managedObjectContext?.save()
      } catch let error {
        print(error)
      }
      DispatchQueue.main.async(){
        self.performSegue(withIdentifier: "transitionToRadio", sender:nil)
      }
    }
    
  }
  private func prepareImageForSaving(image: UIImage, url: String) {
    let date : Double = NSDate().timeIntervalSince1970
    
    convertQueue.async { [weak self] in
      guard let imageData = UIImagePNGRepresentation(image) else {
        print("jpg error")
        return
      }
      
      let thumbnail = image.resizeImage(newWidth: CGFloat(90))
      guard let thumbnailData  = UIImagePNGRepresentation(thumbnail) else {
        print("jpg error")
        return
      }
      
      self?.saveImage(imageData: imageData as NSData, thumbnailData: thumbnailData as NSData, date: date, url: url)
    }
  }

  private func saveImage(imageData:NSData, thumbnailData:NSData, date: Double, url: String) {
    saveQueue.async {
      guard let moc = self.managedObjectContext else {
        return
      }
      let fetchRequest = NSFetchRequest<Thumbnail>(entityName: "Thumbnail")
      let predicate = NSPredicate(format: "url == %@", url)
      fetchRequest.predicate = predicate
      do {
        let fetchResult = try moc.fetch(fetchRequest)
        if fetchResult.count > 0 {
//          DispatchQueue.main.async(){
//            self.performSegue(withIdentifier: "transitionToRadio", sender:nil)
//          }
          return
        }
      } catch {
        fatalError("Failure: \(error)")
      }
      guard let fullRes = NSEntityDescription.insertNewObject(forEntityName: "FullResImage", into: moc) as? FullResImage, let thumbnail = NSEntityDescription.insertNewObject(forEntityName: "Thumbnail", into: moc) as? Thumbnail else {
        print("moc error")
        return
      }
      
      fullRes.imageData = imageData
//      fullRes.url = url
      
      thumbnail.imageData = thumbnailData
      thumbnail.id = date as NSNumber
      thumbnail.url = url
      thumbnail.fullResImage = fullRes
      do {
        try moc.save()
      } catch {
        fatalError("Failure to save context: \(error)")
      }
      
//      moc.refreshAllObjects()
      print ("right before")
    }
  }
  
  private func getListOfRadioStations() {
    let baseUrl = ""
    let uuid = User.getUserUuid(inManagedContext: managedObjectContext!)
    let url = NSURL(string: baseUrl + uuid)
    let task = URLSession.shared.dataTask(with: url! as URL) {[weak self] (data, response, error) in
      if let stations = self?.parseResponse(data: data!) {
        self?.updateDatabase(stations as! Array<NSDictionary>)
      }
    }
    task.resume()
  }
  
  private func printDatabaseStat() {
    managedObjectContext?.perform {
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RadioStation")
      request.predicate = NSPredicate(format: "name = %@", "NRJ")

      if let results = try? self.managedObjectContext!.fetch(request) {
        let a = results.first as! RadioStation
      }
      
    }
  }
}
