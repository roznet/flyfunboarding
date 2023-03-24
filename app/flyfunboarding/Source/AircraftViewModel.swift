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
import SwiftUI

class AircraftViewModel : ObservableObject {
    @Published var registration :String
    @Published var type :String
    typealias Mode = StandardEditButtons.Mode
    @StateObject var flightListViewModel = FlightListViewModel(flights: [], syncWithRemote: false)
    
    var mode : Mode
    var submitText : String {
        switch mode {
        case .create:
            return "Create"
        case .edit:
            return "Edit"
        }
    }
    
    private var originalAircraft : Aircraft

    var aircraft : Aircraft {
        get {
            return self.originalAircraft.with(newRegistration: self.registration, newType: self.type)
        }
        set {
            self.originalAircraft = newValue
            self.registration = newValue.registration
            self.type = newValue.type
        }
    }
   
    init(aircraft: Aircraft, mode: Mode) {
        self.registration = aircraft.registration
        self.type = aircraft.type
        self.originalAircraft = aircraft
        self.mode = mode
        self.flightListViewModel.aircraft = aircraft
        if aircraft.aircraft_identifier != nil {
            self.flightListViewModel.syncWithRemote = true
            self.flightListViewModel.retrieveFlights()
        }
        
        
    }
}
