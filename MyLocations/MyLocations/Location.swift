//
//  Location.swift
//  MyLocations
//
//  Created by 李金钊 on 15/5/26.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class Location: NSManagedObject {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var date: NSDate
    @NSManaged var locationDescription: String
    @NSManaged var category: String
    @NSManaged var placemark: CLPlacemark?

}
