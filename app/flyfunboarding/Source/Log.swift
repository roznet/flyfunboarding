//
//  Log.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
//

import Foundation
import Foundation
import OSLog
import RZUtilsSwift

extension Logger {
    public static let app = RZLogger(subsystem: Bundle.main.bundleIdentifier!, category: "app")
    public static let ui = RZLogger(subsystem: Bundle.main.bundleIdentifier!, category: "ui")
    public static let sync = RZLogger(subsystem: Bundle.main.bundleIdentifier!, category: "sync")
    public static let net = RZLogger(subsystem: Bundle.main.bundleIdentifier!, category: "net")
}

