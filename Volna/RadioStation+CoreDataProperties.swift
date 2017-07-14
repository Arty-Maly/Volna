//
//  RadioStation+CoreDataProperties.swift
//  Volna
//
//  Created by Artem Malyshev on 2/25/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import CoreData


extension RadioStation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RadioStation> {
        return NSFetchRequest<RadioStation>(entityName: "RadioStation");
    }

    @NSManaged public var image: String
    @NSManaged public var name: String
    @NSManaged public var position: Int16
    @NSManaged public var url: String
    @NSManaged public var thumbnail: Thumbnail?
    @NSManaged public var favourite: Bool
  
    public var favouritePosition: Int16?
    {
      get {
        self.willAccessValue(forKey: "favouritePosition")
        let value = self.primitiveValue(forKey: "favouritePosition") as? Int
        self.didAccessValue(forKey: "favouritePosition")
      
        return (value != nil) ? Int16(value!) : nil
      }
      set {
        self.willChangeValue(forKey: "favouritePosition")
      
        let value : Int? = (newValue != nil) ? Int(newValue!) : nil
        self.setPrimitiveValue(value, forKey: "favouritePosition")
      
        self.didChangeValue(forKey: "favouritePosition")
      }
  }

}
