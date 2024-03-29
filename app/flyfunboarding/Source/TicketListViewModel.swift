//  MIT License
//
//  Created on 16/03/2023 for flyfunboarding
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
import OSLog

class TicketListViewModel : ObservableObject {
    @Published var tickets : [Ticket] = []
    
    @Published var flight : Flight = Flight.defaultFlight
    @Published var passenger : Passenger = Passenger.defaultPassenger
    var syncWithRemote : Bool = true
  
    private var filterPassenger : Passenger? = nil
    private var filterFlight : Flight? = nil
    
    init(tickets: [Ticket], passenger: Passenger? = nil, flight: Flight? = nil, syncWithRemote: Bool = true) {
        self.tickets = tickets
        self.syncWithRemote = syncWithRemote
        self.filterFlight = flight
        self.filterPassenger = passenger
        NotificationCenter.default.addObserver(forName: .ticketModified, object: nil, queue: nil) {
            _ in
            self.retrieveTickets()
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func retrieveTickets() {
        if self.syncWithRemote {
            RemoteService.shared.retrieveTicketList(flight: self.filterFlight, passenger: self.filterPassenger) {
                tickets in
                DispatchQueue.main.async {
                    self.tickets = tickets?.sorted(by: { $0.moreRecent(than: $1)}) ?? []
                    
                }
            }
        }
    }
}

extension TicketListViewModel {
    static var empty : TicketListViewModel = TicketListViewModel(tickets: [], syncWithRemote: false)
}
