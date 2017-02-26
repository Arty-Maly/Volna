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
    @NSManaged public var position: Int32
    @NSManaged public var url: String
    @NSManaged public var thumbnail: Thumbnail?

}
