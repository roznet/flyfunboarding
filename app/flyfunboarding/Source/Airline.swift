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

struct Airline: Codable{
    let airlineName : String
    let appleIdentifier : String
    let airlineId : Int?
    let airlineIdentifier : String?

    enum CodingKeys: String, CodingKey {
        case airlineName = "airline_name"
        case appleIdentifier = "apple_identifier"
        case airlineId = "airline_id"
        case airlineIdentifier = "airline_identifier"
    }
   
    init() {
        self.airlineName = ""
        self.appleIdentifier = ""
        self.airlineId = nil
        self.airlineIdentifier = nil
    }
   
    init(airlineName : String, appleIdentifier : String, airlineId : Int?, airlineIdentifier : String?) {
        self.airlineId = airlineId
        self.appleIdentifier = appleIdentifier
        self.airlineName = airlineName
        self.airlineIdentifier = airlineIdentifier
    }
    var validAirline : Bool {
        if self.airlineIdentifier != nil, let airlineId = self.airlineId, airlineId > 0 {
            return true
        }
        return false
    }
    
    func withNewName(name: String) -> Airline {
        return Airline(airlineName: name, appleIdentifier: self.appleIdentifier, airlineId: self.airlineId, airlineIdentifier: self.airlineIdentifier)
    }
}


