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
        case user_full_name = "user_full_name"
        case airline_id = "airline_id"
        
    }
    
    @UserStorage(key: Key.airline_name, defaultValue: "My Airline")
    var airlineName : String
    
    @UserStorage(key: Key.airline_id, defaultValue: -1)
    var airlineId : Int 
   
    @CodableStorage(key: Key.user_full_name)
    var userFullName : PersonNameComponents?
    
    @CodableSecureStorage(key: Key.user_identifier, service: Self.service)
    var userIdentifier : String?
    
    var currentAirline : Airline? {
        get {
            guard let identifier = self.userIdentifier, self.airlineId > 0 else { return nil }
            let rv = Airline(airlineName: self.airlineName, appleIdentifier: identifier, airlineId: self.airlineId)
            return rv
        }
        set {
            if let airline = newValue {
                if airline.validAirline {
                    self.userIdentifier = airline.appleIdentifier
                    self.airlineName = airline.airlineName
                    self.airlineId = airline.airlineId ?? -1
                }
            }else if newValue == nil {
                self.userIdentifier = nil
                self.airlineId = -1
                self.airlineName = "My Airline"
            }
            
        }
    }
    
}
