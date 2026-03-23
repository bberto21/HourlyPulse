//
//  MinuteParser.swift
//  MinuteMark
//
//  Created by Admin on 3/17/26.
//

import Foundation

struct MinuteParser {

    static func parse(_ input: String) -> [Int] {
        let values = input
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { $0 >= 0 && $0 <= 59 }

        return Array(Set(values)).sorted()
    }
}
