//  MIT License
//
//  Created on 13/03/2023 for flyfunboarding
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
import RZFlight
import CryptoKit

struct Flight : Codable, Identifiable{
    struct ICAO : Codable, Identifiable {
        var id : Int { return icao.hashValue }
        var icao : String
        
        enum CodingKeys: CodingKey {
            case icao
        }
        
        lazy var airport : Airport? = { try? Airport(db: FlyFunBoardingApp.db, ident: self.icao) }()
    }
    
    var id : Int { return self.flight_id ?? -1 }
    
    var destination : ICAO
    var origin : ICAO
    var gate : String
    var flightNumber : String
    var aircraft : Aircraft
    var scheduledDepartureDate : Date
    var flight_id : Int?
    var flight_identifier : String?
    
    enum CodingKeys: CodingKey {
        case destination
        case origin
        case gate
        case flightNumber
        case aircraft
        case scheduledDepartureDate
        case flight_id
        case flight_identifier
    }
    
    func with(destination: ICAO? = nil, origin: ICAO? = nil,
              gate: String? = nil, flightNumber: String? = nil,
              aircraft: Aircraft? = nil, scheduledDepartureDate: Date? = nil) -> Flight {
        let rv = Flight(destination: destination ?? self.destination,
                        origin: origin ?? self.origin,
                        gate: gate ?? self.gate,
                        flightNumber: flightNumber ?? self.flightNumber,
                        aircraft: aircraft ?? self.aircraft,
                        scheduledDepartureDate: scheduledDepartureDate ?? self.scheduledDepartureDate,
                        flight_id: self.flight_id, flight_identifier: self.flight_identifier)
        return rv
    }
    // Needs to be kept consistent with PHP service class
    func uniqueIdentifier() -> String? {
        let dateFormatter = DateFormatter()
        
        let tag = String(format: "%@%@.%@.%@", self.origin.icao, self.destination.icao,
                         self.aircraft.registration,
                         dateFormatter.string(from: self.scheduledDepartureDate))
        
        return SHA256.hash(string: tag)?.hashString
    }

}
