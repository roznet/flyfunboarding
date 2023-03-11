//
//  Airline.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
//

import Foundation

struct Airline: Codable{
    let airlineName : String
    let appleIdentifier : String
    let airlineId : Int? 

    enum CodingKeys: String, CodingKey {
        case airlineName = "airline_name"
        case appleIdentifier = "apple_identifier"
        case airlineId = "airline_id"
    }
   
    init() {
        self.airlineName = ""
        self.appleIdentifier = ""
        self.airlineId = nil
    }
   
    init(airlineName : String, appleIdentifier : String, airlineId : Int?) {
        self.airlineId = airlineId
        self.appleIdentifier = appleIdentifier
        self.airlineName = airlineName
    }
    var validAirline : Bool {
        if let airlineId = self.airlineId, airlineId > 0 {
            return true
        }
        return false
    }
}


