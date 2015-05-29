//
//  Functions.swift
//  MyLocations
//
//  Created by 李金钊 on 15/5/25.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

import Foundation
import Dispatch

let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as! [String]
    return paths[0]
}()

func afterDelay(seconds: Double, closure: () ->()){
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(when, dispatch_get_main_queue(), closure)
}

