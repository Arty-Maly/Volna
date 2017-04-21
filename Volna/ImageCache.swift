
//
//  ImageCache.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit
import CoreData
final class ImageCache {
  
  static let shared = ImageCache()
  var managedObjectContext: NSManagedObjectContext
  private var cache = [String: UIImage]()
  
  private init() {
    
    self.managedObjectContext = ((UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext)!
  }
  
  subscript(key: String, quality: String) -> UIImage? {
    
    get {
      if cache[key] == nil {
        loadImage(url: key)
      }
      return cache[key+quality]
    }    
//    set (newValue) {
//      cache[key] = newValue
//    }
  }
  
  private func loadImage(url: String) {
    let fetchRequest = NSFetchRequest<Thumbnail>(entityName: "Thumbnail")
    fetchRequest.predicate = NSPredicate(format: "url = %@", url)

    do {
      let result = try managedObjectContext.fetch(fetchRequest)
      if let imageData = result.first {
        let sdImage = UIImage(data: imageData.imageData as Data)!
        let hdImage = UIImage(data: imageData.fullResImage.imageData! as Data)!
        cache[url+"SD"] = sdImage
        cache[url+"HD"] = hdImage
      } else {
        cache[url+"SD"] = UIImage(named: "placeholder.png")!
        cache[url+"HD"] = UIImage(named: "placeholder.png")!
      }
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
    }
  }
}

