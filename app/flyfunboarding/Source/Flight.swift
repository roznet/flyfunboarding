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
    var scheduleDepartureDate : Date
    var flight_id : Int?
    
    enum CodingKeys: CodingKey {
        case destination
        case origin
        case gate
        case flightNumber
        case aircraft
        case scheduleDepartureDate
    }
}
