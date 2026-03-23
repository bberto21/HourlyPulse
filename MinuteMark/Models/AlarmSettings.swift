//
//  AlarmSettings.swift
//  MinuteMark
//
//  Created by Admin on 3/17/26.
//

import Foundation

struct AlarmSettings: Codable {
    var minutes: [Int]
    var startHour: Int
    var endHour: Int
    var soundName: String

    init(
        minutes: [Int],
        startHour: Int = 0,
        endHour: Int = 23,
        soundName: String
    ) {
        self.minutes = minutes
        self.startHour = startHour
        self.endHour = endHour
        self.soundName = soundName
    }
}
