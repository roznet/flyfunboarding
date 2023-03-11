//
//  Settings.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
//

import Foundation
import RZUtilsSwift

struct Settings {
    static let service = "flyfunboarding.ro-z.net"
    static var shared : Settings = Settings()
    
    enum Key : String {
        case airline_name = "airline_name"
        case user_identifier = "user_identifier"
        
    }
    
    @UserStorage(key: Key.airline_name, defaultValue: "My Airline")
    var airlineName : String
    
    @CodableSecureStorage(key: Key.user_identifier, service: Self.service)
    var userIdentifier : String?
}
