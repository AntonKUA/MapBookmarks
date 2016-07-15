//
//  Venue.swift
//  MapBookmarksApp
//
//  Created by Anton Komir on 7/15/16.
//  Copyright © 2016 Anton Komir. All rights reserved.
//

import RealmSwift
import MapKit

class Venue: Object
{
    dynamic var id:String = ""
    dynamic var name:String = ""
    
    dynamic var latitude:Float = 0
    dynamic var longitude:Float = 0
    
    dynamic var address:String = ""
    
    var coordinate:CLLocation {
        return CLLocation(latitude: Double(latitude), longitude: Double(longitude));
    }
    
    override static func primaryKey() -> String?
    {
        return "id";
    }
}
