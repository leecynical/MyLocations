//
//  String+AddText.swift
//  MyLocations
//
//  Created by 李金钊 on 15/6/1.
//  Copyright (c) 2015年 lijinzhao. All rights reserved.
//

extension String {
    mutating func addText(text: String?, withSeparator separator: String = ""){
        if let text = text {
            if !isEmpty{
                self += separator
            }
            self += text
        }
    }
}
