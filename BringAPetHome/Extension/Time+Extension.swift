//
//  Time+Extension.swift
//  BringAPetHome
//
//  Created by Ting on 2022/7/3.
//

import Foundation
import UIKit

let currentDate = Date()
let pasteDate = Date(timeIntervalSinceNow: -60 * 60 * 24 * 7)

extension Date {
    func displayTimeInSocialMediaStyle() ->  String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        
        if secondsAgo < minute {
            return "\(secondsAgo) second ago"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute) minutes ago"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour) hours ago"
        } else if secondsAgo < week {
            return "\(secondsAgo / day) days ago"
        }
        return "\(secondsAgo / week) weeks ago"
    }
}
