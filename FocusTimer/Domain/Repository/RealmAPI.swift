//
//  RealmAPI.swift
//  LookIntoMind
//
//  Created by jh on 2023/11/28.
//

import Foundation
import RealmSwift

class RealmAPI {
    static let shared = RealmAPI()
    private init() { }

    
    func save(item: DataModel) throws -> Bool {
        do {
            let realm = try Realm()
            let oldData = realm.objects(RealmDataModel.self).filter{ $0.date.summary == item.date.summary }.first
            
            print("item.date.summary:\(item.date.summary)")
            print("oldData:\(oldData?.date.summary)")
            try realm.write {
                print("123")
                if let oldData = oldData {
                    let oldDataTime: Int = oldData.seconds
                    realm.delete(oldData)
                    let newData = RealmDataModel(date: item.date, seconds: item.seconds + oldDataTime)
                    realm.add(newData)
                } else {
                    let newData = RealmDataModel(date: item.date, seconds: item.seconds)
                    realm.add(newData)
                }
                
                debugPrint("🔵 Realm API save success")
            }
        } catch {
            debugPrint("❌ Realm API save error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    func load() throws -> [DataModel] {
        do {
            let realm = try Realm()
            let items = realm.objects(RealmDataModel.self)
            var data: [DataModel] = []
            for item in items {
                data.append(DataModel(date: item.date, seconds: item.seconds))
            }
            // date 기준 정렬
            data = data.sorted(by: { lhs, rhs in
                return lhs.date > rhs.date
            })
            debugPrint("🔵 Realm API load success")
            return data
        } catch {
            debugPrint("❌ Realm API load error: \(error.localizedDescription)")
            throw error
        }
    }
    
}
