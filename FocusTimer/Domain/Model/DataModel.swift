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
    [.init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 04))!, seconds: 5),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 08))!, seconds: 853),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 12))!, seconds: 123),
     .init(date: Calendar.current.date(from: DateComponents(year: 2024, month: 07, day: 21))!, seconds: 3754),
    ]
}
