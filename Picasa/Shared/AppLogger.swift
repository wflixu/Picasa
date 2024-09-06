//
//  AppLogger.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/5.
//

import OSLog

@propertyWrapper
struct AppLog {

    private let logger: Logger

    init(subsystem: String = Bundle.main.bundleIdentifier ?? "", category: String = "main") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    var wrappedValue: Logger {
        return logger
    }
}

