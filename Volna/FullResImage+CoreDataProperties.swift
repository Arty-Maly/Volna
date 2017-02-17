//
//  FullResImage+CoreDataProperties.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import CoreData


extension FullResImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FullResImage> {
        return NSFetchRequest<FullResImage>(entityName: "FullResImage");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var thumbnail: Thumbnail?

}
