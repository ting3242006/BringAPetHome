//
//  User+CoreDataProperties.swift
//  
//
//  Created by Ting on 2022/6/19.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var like: Bool

}
