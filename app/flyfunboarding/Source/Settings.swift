//  MIT License
//
//  Created on 12/03/2023 for flyfunboarding
//
//  Copyright (c) 2023 Brice Rosenzweig
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//


import Foundation
import RZUtilsSwift
import OSLog

extension Notification.Name {
    static let signinStatusChanged = Notification.Name("signinStatusChanged")
}

struct Settings {
    static let service = "flyfunboarding.ro-z.net"
    static var shared : Settings = Settings()
    
    enum Key : String {
        case airline_name = "airline_name"
        case user_identifier = "user_identifier"
        case user_full_name = "user_full_name"
        case airline_id = "airline_id"
        case airline_identifier = "airline_identifier"
        case last_latitude = "last_latitude"
        case last_longitude = "last_longitude"
        case airline_public_key = "airline_public_key"
        case last_airports_ident = "last_airports_ident"
        case last_aircraft_ident = "last_aircraft_ident"
        case airline_settings = "airline_settings"
        
    }
  
    @UserStorage(key: Key.last_latitude, defaultValue: 51.50)
    var lastLatitude : Double
    @UserStorage(key: Key.last_longitude, defaultValue: 0.12)
    var lastLongitude : Double
    
    @UserStorage(key: Key.last_airports_ident, defaultValue: [])
    var lastAirportsIdent : [String]
    
    @UserStorage(key: Key.airline_name, defaultValue: "My Airline")
    var airlineName : String
    
    @UserStorage(key: Key.airline_id, defaultValue: -1)
    var airlineId : Int
    
    @UserStorage(key: Key.airline_public_key, defaultValue: "")
    var airlinePublicKey : String
   
    @CodableStorage(key: Key.user_full_name, defaultValue: nil)
    var userFullName : PersonNameComponents?
    
    @CodableSecureStorage(key: Key.user_identifier, service: Self.service)
    var userIdentifier : String?
    
    @CodableSecureStorage(key: Key.airline_identifier, service: Self.service)
    var airlineIdentifier : String?
    
    @CodableStorage(key: Key.airline_settings, defaultValue: nil)
    var currentAirlineSettings : Airline.Settings?
        
    var currentAirline : Airline? {
        get {
            guard
                let airlineIdentifier = self.airlineIdentifier,
                let identifier = self.userIdentifier,
                self.airlineId > 0
            else { return nil }
            
            let rv = Airline(airlineName: self.airlineName, appleIdentifier: identifier, airlineId: self.airlineId, airlineIdentifier: airlineIdentifier)
            return rv
        }
        set {
            if let airline = newValue {
                if airline.validAirline {
                    if self.userIdentifier != airline.appleIdentifier {
                        Logger.app.info("changing airline, resetting publicKey for \(airline.appleIdentifier)")
                        self.airlinePublicKey = ""
                    }
                    self.userIdentifier = airline.appleIdentifier
                    self.airlineName = airline.airlineName
                    self.airlineId = airline.airlineId ?? -1
                    self.airlineIdentifier = airline.airlineIdentifier
                }
            }else if newValue == nil {
                self.userIdentifier = nil
                self.airlineId = -1
                self.airlineName = "My Airline"
                self.airlineIdentifier = nil
                self.airlinePublicKey = ""
            }
            NotificationCenter.default.post(name: .signinStatusChanged, object: self)
        }
    }
    mutating func notice(lastAirportIdent : String) {
        let list = self.lastAirportsIdent
        if let last = list.last {
            if last != lastAirportIdent {
                self.lastAirportsIdent = [last, lastAirportIdent]
            }
        }else{
            self.lastAirportsIdent = [ lastAirportIdent ]
        }
    }
}
