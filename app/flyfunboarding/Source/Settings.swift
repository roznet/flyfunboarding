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
