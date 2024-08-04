//
//  SoundModule.swift
//  FocusTimer
//
//  Created by jh on 8/3/24.
//

import Foundation
import AudioToolbox

class SoundModule {
    private let soundDirectory = "/System/Library/Audio/UISounds/New"
    private var soundList: [String] = []
    
    func soundOutput(sw2: Bool) {
        if sw2 {
            guard let soundList = FileManager.default.enumerator(atPath: soundDirectory) else { return }
            let soundFileName = soundList.map { String(describing: $0) }[4]
            let fullyQualifiedName = soundDirectory + "/" + soundFileName
            let url = URL(fileURLWithPath: fullyQualifiedName)
            var soundId: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
            AudioServicesPlaySystemSoundWithCompletion(soundId, {
                AudioServicesDisposeSystemSoundID(soundId)
            })
        }
    }
}
