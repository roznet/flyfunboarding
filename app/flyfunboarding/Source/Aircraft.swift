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
import CryptoKit


class Aircraft: Codable, Identifiable, Hashable,Equatable {
    static func == (lhs: Aircraft, rhs: Aircraft) -> Bool {
        return lhs.registration == rhs.registration
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.registration)
    }
    
    var registration: String
    var type: String
    var stats : [Stats]?
    var aircraft_id: Int?
    var aircraft_identifier : String?
    
    enum CodingKeys: String, CodingKey {
        case registration, type, aircraft_id, aircraft_identifier,stats
    }
    
    var id = UUID()
    
    init(registration: String, type: String, aircraft_id: Int? = nil, aircraft_identifier: String? = nil) {
        self.registration = registration
        self.type = type
        self.aircraft_id = aircraft_id
        self.aircraft_identifier = aircraft_identifier
    }

    func with(newRegistration: String, newType: String) -> Aircraft {
        return Aircraft(registration: newRegistration, type: newType, aircraft_id: self.aircraft_id, aircraft_identifier: self.aircraft_identifier)
    }
    
    static var defaultAircraft : Aircraft {
        return Aircraft(registration: "", type: "Cirrus SR22T")
    }
   
    func moreRecent(than : Aircraft) -> Bool {
        if let a = self.stats?.first, let b = than.stats?.first {
            return a.moreRecent(than: b)
        }
        return self.stats?.first != nil
    }
}

extension Aircraft : CustomStringConvertible{
    var description: String {
        var components = [ self.registration, self.type]
        if let id = self.aircraft_identifier {
            components.append(id.shortenedPoint)
        }
        let args = components.joined(separator: ", ")
        return "Aircraft(\(args))"
    }
}
