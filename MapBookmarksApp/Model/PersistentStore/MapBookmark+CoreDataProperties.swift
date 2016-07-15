//
//  MapBookmark+CoreDataProperties.swift
//  
//
//  Created by Anton Komir on 7/14/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MapBookmark {

    @NSManaged var title: String?
    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var data: NSDate?

}
