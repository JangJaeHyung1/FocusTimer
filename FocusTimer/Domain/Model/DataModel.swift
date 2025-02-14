//
//  DataModel.swift
//  FocusTimer
//
//  Created by jh on 7/31/24.
//

import Foundation

struct DataModel: Codable {
    var date: Date
    var seconds: Int
}


struct Dummy {
    static var data: [DataModel] =
    [.init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 05))!, seconds: 3600 + 1800),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 09))!, seconds: 3600 * 4),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 13))!, seconds: 3600 * 6 + 1800),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 15))!, seconds: 3600 * 9 + 900),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 17))!, seconds: 3600 * 13),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 19))!, seconds: 3600 * 12 + 900),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 22))!, seconds: 3000),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 23))!, seconds: 3000),


    ]
}
