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

class FlightListViewModel : ObservableObject {
    @Published var flights : [Flight] = []
    var syncWithRemote : Bool = true
    var aircraft : Aircraft? = nil
    
    static var empty = FlightListViewModel(flights: [], syncWithRemote: false)
    
    init(flights : [Flight], aircraft : Aircraft? = nil, syncWithRemote: Bool = true) {
        self.syncWithRemote = syncWithRemote
        self.flights = flights.sorted(by: { $0.moreRecent(than: $1)})
        if let aircraft = aircraft {
            if aircraft.aircraft_identifier != nil {
                self.aircraft = aircraft
            }
        }
        NotificationCenter.default.addObserver(forName: .flightModified, object: nil, queue: nil){
            _ in
            self.retrieveFlights()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func retrieveFlights() {
        if syncWithRemote {
            RemoteService.shared.retrieveFlightList(aircraft: self.aircraft) {
                flights in
                DispatchQueue.main.async {
                    self.flights = flights?.sorted(by: { $0.moreRecent(than: $1)}) ?? []
                }
            }
        }
    }
    func guessNextFlight() -> Flight {
        if let last = self.flights.first {
            return last.asNewFlight
        }
        return Flight.defaultFlight
    }

}
