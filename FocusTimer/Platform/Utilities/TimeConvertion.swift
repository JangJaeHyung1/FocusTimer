//
//  SecondConvert.swift
//  FocusTimer
//
//  Created by jh on 8/1/24.
//

import Foundation

class TimeConvertion {
    static let shared = TimeConvertion()
    func convertSeconds(seconds: Int) -> String {
        let minute = Int(seconds / 60)
        let second = seconds % 60
        var strMinute: String = "\(minute)"
        var strSecond: String = "\(second)"
        if minute < 10 {
            strMinute = "0" + strMinute
        }
        if second < 10 {
            strSecond = "0" + strSecond
        }
        return strMinute + ":" + strSecond
    }
    func convertMinute(seconds: Int) -> String {
        let hour = Int(seconds / 3600)
        let minute = Int( (seconds % 3600 ) / 60)
        var strHour: String = "\(hour)"
        var strMinute: String = "\(minute)"
        if hour < 10 {
            strHour = "0" + strHour
        }
        if minute < 10 {
            strMinute = "0" + strMinute
        }
        return strHour + ":" + strMinute
    }
}
