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

class FlightViewModel : ObservableObject {
    typealias Mode = StandardEditButtons.Mode
    @Published var origin : String
    @Published var destination : String
    @Published var scheduledDepartureDate : Date
    @Published var aircraft : Aircraft
    @Published var gate : String
    @Published var flightNumber : String
    
    
    var mode : Mode
    
    var submitText : String {
        switch mode {
        case .create:
            return "Schedule"
        case .edit:
            return "Amend"
        }
    }
    
    private var originalFlight : Flight
    
    var flight : Flight {
        get {
            return originalFlight.with(destination: Flight.ICAO(icao: self.destination),
                                       origin: Flight.ICAO(icao: self.origin),
                                       gate: self.gate,
                                       flightNumber: self.flightNumber,
                                       aircraft: aircraft,
                                       scheduledDepartureDate: self.scheduledDepartureDate)
        }
        set {
            self.originalFlight = newValue
            self.origin = newValue.origin.icao
            self.destination = newValue.destination.icao
            self.scheduledDepartureDate = newValue.scheduledDepartureDate
            self.gate = newValue.gate
            self.flightNumber = newValue.flightNumber
            self.aircraft = newValue.aircraft
        }
    }
    
    init(flight : Flight, mode : Mode) {
        self.originalFlight = flight
        self.origin = flight.origin.icao
        self.destination = flight.destination.icao
        self.scheduledDepartureDate = flight.scheduledDepartureDate
        self.aircraft = flight.aircraft
        self.gate = flight.gate
        self.flightNumber = flight.flightNumber
        self.mode = mode
    }
}
