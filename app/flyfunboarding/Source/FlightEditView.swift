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



import SwiftUI
import OSLog

extension Notification.Name {
    static let flightModified = Notification.Name("flightModified")
}

struct FlightEditView: View {
    @StateObject var flightModel : FlightViewModel
    @StateObject var ticketListViewModel : TicketListViewModel
    @Environment(\.dismiss) var dismiss
    var editIsDisabled : Bool = false
    @State private var isPresentingConfirm : Bool = false
    
    init(flight: Flight, mode: FlightViewModel.Mode, syncWithRemote: Bool = true, editIsDisabled: Bool = false){
        _flightModel = StateObject(wrappedValue: FlightViewModel(flight: flight, mode: mode))
        _ticketListViewModel = StateObject(wrappedValue: TicketListViewModel(tickets: [], flight: flight, syncWithRemote: syncWithRemote))
        self.editIsDisabled = editIsDisabled
    }
    var body: some View {
        ScrollView {
            VStack {
                AircraftPicker(aircraftRegistration: flightModel.aircraft.registration, aircraft: $flightModel.aircraft)
                    .disabled(self.editIsDisabled || self.flightModel.mode == .edit)
                DatePicker("Flight Departure", selection: $flightModel.scheduledDepartureDate)
                    .disabled(self.editIsDisabled)
                AirportPicker(labelText: "Departure", icao: $flightModel.origin, name: "Fairoaks")
                    .disabled(self.editIsDisabled)
                AirportPicker(labelText: "Destination", icao: $flightModel.destination, name: "Le Touquet", editIsDisabled: self.editIsDisabled)
                HStack {
                    Text("Gate")
                        .standardFieldLabel()
                    TextField("Gate", text: $flightModel.gate)
                        .standardStyle()
                        .disabled(self.editIsDisabled)
                }
                HStack {
                    Text("Flight Number")
                        .standardFieldLabel()
                    TextField("Flight Number", text: $flightModel.flightNumber)
                        .standardStyle()
                        .disabled(self.editIsDisabled)
                    
                }
                if !self.editIsDisabled {
                    StandardEditButtons(mode: self.flightModel.mode,
                                        submit: self.flightModel.submitText,
                                        delete: "Delete",
                                        submitAction: scheduleOrAmend,
                                        deleteAction: delete)
                    if self.ticketListViewModel.tickets.count > 0 {
                        VStack {
                            HStack {
                                Text("Tickets").standardFieldLabel()
                                Spacer()
                            }
                            List(self.ticketListViewModel.tickets) { ticket in
                                NavigationLink(value: ticket){
                                    TicketRowView(ticket: ticket)
                                }
                            }
                        }
                    }
                }
            }
        }.onAppear() {
            self.ticketListViewModel.retrieveTickets()
        }
    }
    private func remoteCompletion(flight : Flight?, mode : FlightViewModel.Mode) {
        if let f = flight {
            // update in case we get a new identifier
            Logger.ui.info( mode == .edit ? "Amended \(f)" : "Scheduled \(f)")
            DispatchQueue.main.async {
                self.flightModel.flight = f
                self.flightModel.mode = .edit
                NotificationCenter.default.post(name: .flightModified, object: nil)
            }
        }else{
            Logger.ui.error("Failed to schedule flight")
        }
        
    }
    func scheduleOrAmend() {
        let newFlight = self.flightModel.flight
        switch self.flightModel.mode {
        case .edit:
            RemoteService.shared.amendFlight(flight: newFlight){ self.remoteCompletion(flight: $0, mode: .edit) }
        case .create:
            RemoteService.shared.scheduleFlight(flight: newFlight.asNewFlight){ self.remoteCompletion(flight: $0, mode: .create) }
        }
    }
    
    func delete() {
        Logger.ui.info("Delete flight")
        RemoteService.shared.deleteFlight(flight: self.flightModel.flight){
            result in
            if result {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .flightModified, object: nil)
                    self.dismiss()
                }
            }
                    
        }
    }
}

struct FlightEditView_Previews: PreviewProvider {
    static var previews: some View {
        let flights = Samples.flights
        FlightEditView(flight: flights[0], mode: .create)
    }
}
