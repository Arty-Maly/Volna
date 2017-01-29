//
//  User+CoreDataClass.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {

  
  class func getUserUuid(inManagedContext context: NSManagedObjectContext) -> String {
    var  uuid = ""
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
    if let user = (try? context.fetch(request))?.first as? User {
      uuid = user.uuid!
    } else if let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as? User {
      user.uuid = NSUUID().uuidString
      uuid = user.uuid!
      do {
        try context.save()
      } catch let error {
        print(error)
      }
    }
    return uuid
  }
}
