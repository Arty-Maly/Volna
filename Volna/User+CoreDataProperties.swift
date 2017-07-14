//
//  User+CoreDataProperties.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var uuid: String?
    @NSManaged public var timesOpened: Int32
    @NSManaged public var askForReview: Bool

}
