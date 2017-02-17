
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
  
  subscript(key: String) -> UIImage? {
    get {
      if cache[key] == nil {
        loadImage(url: key)
      }
      return cache[key]
    }
    
    set (newValue) {
      cache[key] = newValue
    }
  }
  
  private func loadImage(url: String) {
    let fetchRequest = NSFetchRequest<Thumbnail>(entityName: "Thumbnail")
    fetchRequest.predicate = NSPredicate(format: "url = %@", url)
    
    do {
      let result = try managedObjectContext.fetch(fetchRequest)
      let imageData = result.first!
      let image = UIImage(data: imageData.imageData as! Data)!
      cache[url] = image
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
    }
  }
}

