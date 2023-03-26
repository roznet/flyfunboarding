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
import RZUtilsSwift
import OSLog

struct Ticket : Codable, Identifiable {
    var passenger : Passenger
    var flight : Flight
    var seatNumber : String
    var ticket_id : Int?
    var ticket_identifier : String?
    
    var id : Int { return self.ticket_id ?? -1 }
    
    static var defaultTicket : Ticket = {
        return Ticket(passenger: Passenger.defaultPassenger, flight: Flight.defaultFlight, seatNumber: "")
    }()
    
    func with(seatNumber : String) -> Ticket {
        return Ticket(passenger: self.passenger, flight: self.flight, seatNumber: seatNumber, ticket_id: self.ticket_id, ticket_identifier: self.ticket_identifier)
    }
    var downloadPassUrl : URL? {
        if let identifier = ticket_identifier {
            let baseUrl = Secrets.shared.flyfunBaseUrl
            let point = "boardingPass/\(identifier)"
            if let url = URL(string: point, relativeTo: baseUrl ) {
                Logger.app.info("Sharing \(url.absoluteURL)")
                return url.absoluteURL
            }
        }
        return nil
    }

    var disclaimerUrl : URL? {
        if let identifier = ticket_identifier {
            let baseUrl = Secrets.shared.flyfunBaseUrl.absoluteString.replacing("/api", with: "/pages")
            let point = "yourBoardingPass?ticket=\(identifier)"
            if let url = URL(string: point, relativeTo: URL(string: baseUrl) ) {
                Logger.app.info("Sharing \(url.absoluteURL)")
                return url.absoluteURL
            }
        }
        return nil

    }
    
    func moreRecent(than : Ticket) -> Bool {
        return self.flight.moreRecent(than: than.flight)
    }
}

extension Ticket {
    struct Signature : Codable {
        let ticket : String
        let signature : String
    }
}
