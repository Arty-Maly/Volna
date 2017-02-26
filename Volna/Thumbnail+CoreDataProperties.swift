//
//  Thumbnail+CoreDataProperties.swift
//  Volna
//
//  Created by Artem Malyshev on 2/25/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import CoreData


extension Thumbnail {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Thumbnail> {
        return NSFetchRequest<Thumbnail>(entityName: "Thumbnail");
    }

    @NSManaged public var id: NSNumber
    @NSManaged public var imageData: NSData
    @NSManaged public var url: String
    @NSManaged public var fullResImage: FullResImage
    @NSManaged public var radioStation: RadioStation

}
