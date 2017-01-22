//
//  RadioStation+CoreDataProperties.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import CoreData


extension RadioStation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RadioStation> {
        return NSFetchRequest<RadioStation>(entityName: "RadioStation");
    }

    @NSManaged public var name: String?
    @NSManaged public var url: String?
    @NSManaged public var position: Int32

}
