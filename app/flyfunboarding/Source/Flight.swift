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

struct Flight : Codable, Identifiable, Hashable, Equatable{
    struct ICAO : Codable, Identifiable {
        var id : Int { return icao.hashValue }
        var icao : String
        
        enum CodingKeys: CodingKey {
            case icao
        }
        
        lazy var airport : Airport? = { try? Airport(db: FlyFunBoardingApp.db, ident: self.icao) }()
    }
    
    static func == (lhs: Flight, rhs: Flight) -> Bool {
        return lhs.flight_identifier == rhs.flight_identifier
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.flight_identifier)
    }
    
    var id = UUID()
    
    var destination : ICAO
    var origin : ICAO
    var gate : String
    var flightNumber : String
    var aircraft : Aircraft
    var scheduledDepartureDate : Date
    var flight_id : Int?
    var flight_identifier : String?
    var stats : [Stats]? = nil
    
    enum CodingKeys: CodingKey {
        case destination
        case origin
        case gate
        case flightNumber
        case aircraft
        case scheduledDepartureDate
        case flight_id
        case flight_identifier
        case stats
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
    
    var asNewFlight : Flight {
        let rv = Flight(destination: destination ,
                        origin: origin ,
                        gate: gate ,
                        flightNumber: flightNumber ,
                        aircraft: aircraft ,
                        scheduledDepartureDate: scheduledDepartureDate ,
                        flight_id: nil, flight_identifier: nil)
        return rv

    }

    static var defaultFlight : Flight {
        return Flight(destination: ICAO(icao: "EGTF"),
                      origin: ICAO(icao: "LFAT"),
                      gate: "",
                      flightNumber: "",
                      aircraft: Aircraft.defaultAircraft,
                      scheduledDepartureDate: Date())
    }
    
    func moreRecent(than : Flight) -> Bool {
        return self.scheduledDepartureDate > than.scheduledDepartureDate
    }
}

extension Flight : CustomStringConvertible {
    var description: String {
        var components : [String] = [ self.origin.icao, self.destination.icao, self.scheduledDepartureDate.formatted(date: .abbreviated, time: .shortened), self.aircraft.description]
        if let id = self.flight_identifier {
            components.append(id.shortenedPoint)
        }
        let args = components.joined(separator: ", ")
        
        return "Flight(\(args))"
    }
}
