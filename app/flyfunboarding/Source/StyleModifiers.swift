//  MIT License
//
//  Created on 19/03/2023 for flyfunboarding
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


extension TextField {
    func standardStyle() -> some View {
        return self.textFieldStyle(.roundedBorder)
    }
}
extension List {
    func standardNavigationDestinations() -> some View {
        return self
            .navigationDestination(for: Aircraft.self){
                aircraft in
                AircraftEditView(aircraft: aircraft, mode: .edit)
            }
            .navigationDestination(for: Flight.self){
                flight in
                FlightEditView(flight: flight, mode: .edit)
            }
            .navigationDestination(for: Ticket.self){
                ticket in
                // Should be edit view once we have proper constructor
                TicketEditView(ticket: ticket, mode: .edit)
            }
            .navigationDestination(for: Passenger.self) {
                passenger in
                PassengerEditView(passenger: passenger)
            }
    }
}
extension Text {
    func standardFieldLabel() -> some View {
        return self.font(.headline)
    }
    func standardFieldValue() -> some View {
        return self.font(.body)
    }
    func standardInfo() -> some View {
        return self.font(.footnote).foregroundColor(.gray)
    }
}

extension Button {
    func standardButton() -> some View {
        return self.buttonStyle(.bordered)
    }
}

extension View {
    func standardNavigationBarTitle(_ text : String) -> some View {
        return self.navigationBarTitle(text, displayMode: .inline)
    }
}
