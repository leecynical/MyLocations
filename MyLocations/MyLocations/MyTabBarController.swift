//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by 李金钊 on 15/6/1.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
