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

    static func configure() {
        var configuration = Realm.Configuration.defaultConfiguration
        guard configuration.schemaVersion < 1 else { return }

        configuration.schemaVersion = 1
        configuration.migrationBlock = { _, _ in
            // Realm automatically initializes completedSessionIDs for existing records.
        }
        Realm.Configuration.defaultConfiguration = configuration
    }

    
    func save(item: DataModel) throws -> Bool {
        do {
            let realm = try Realm()
            let oldData = realm.objects(RealmDataModel.self).filter{ $0.date.summary == item.date.summary }.first
            
//            print("item.date.summary:\(item.date.summary)")
//            print("oldData:\(oldData?.date.summary)")
            try realm.write {
//                print("123")
                if let oldData = oldData {
                    oldData.seconds += item.seconds
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

    /// Saves a completed timer exactly once, even if foreground and notification
    /// callbacks try to reconcile the same session at nearly the same time.
    func saveCompletedSession(item: DataModel, sessionID: String) throws -> Bool {
        let realm = try Realm()
        let oldData = realm.objects(RealmDataModel.self)
            .first { $0.date.summary == item.date.summary }

        if oldData?.completedSessionIDs.contains(sessionID) == true {
            return false
        }

        try realm.write {
            if let oldData {
                oldData.seconds += item.seconds
                oldData.completedSessionIDs.append(sessionID)
            } else {
                let newData = RealmDataModel(date: item.date, seconds: item.seconds)
                newData.completedSessionIDs.append(sessionID)
                realm.add(newData)
            }
        }

        debugPrint("🔵 Realm completed timer save success")
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
