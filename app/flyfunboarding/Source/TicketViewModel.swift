//  MIT License
//
//  Created on 22/03/2023 for flyfunboarding
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
import SwiftUI

class TicketViewModel : ObservableObject {
    typealias Mode = StandardEditButtons.Mode
    
    @Published var flight : Flight
    @Published var passenger : Passenger
    @Published var seatNumber : String
    var mode : Mode
    var submitText : String {
        switch mode {
        case .create:
            return "Issue"
        case .edit:
            return "Update"
        }
    }
    var ticket : Ticket {
        get {
            return self.originalTicket.with(seatNumber: self.seatNumber)
        }
        set {
            self.originalTicket = newValue
            self.flight = newValue.flight
            self.passenger = newValue.passenger
            self.seatNumber = newValue.seatNumber
        }
    }
    private var originalTicket : Ticket
    
    var isIssued : Bool { return self.originalTicket.ticket_identifier != nil }
  
    init(ticket: Ticket, mode : Mode) {
        self.flight = ticket.flight
        self.passenger = ticket.passenger
        self.originalTicket = ticket
        self.seatNumber =  ticket.seatNumber
        self.mode = mode
    }
}

