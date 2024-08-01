//
//  RealmDataModel.swift
//  FocusTimer
//
//  Created by jh on 8/1/24.
//

import Foundation
import RealmSwift

class RealmDataModel: Object {
    @Persisted(indexed: true) var date: Date // primary key로 지정
    @Persisted var seconds: Int
    convenience init(date: Date, seconds: Int) {
        self.init()
        self.date = date
        self.seconds = seconds
    }
}
