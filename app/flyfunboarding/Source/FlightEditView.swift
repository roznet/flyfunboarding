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
    @State private var isPresentingConfirm : Bool = false
    @Environment(\.isEnabled) private var isEnabled;
    
    init(flight: Flight,
         mode: FlightViewModel.Mode,
         tickets: [Ticket] = [],
         syncWithRemote: Bool = true,
         editIsDisabled: Bool = false){
        _flightModel = StateObject(wrappedValue: FlightViewModel(flight: flight, mode: mode))
        _ticketListViewModel = StateObject(wrappedValue: TicketListViewModel(tickets: tickets, flight: flight, syncWithRemote: syncWithRemote))
    }
    var body: some View {
        VStack {
            VStack {
                AircraftField(aircraft: flightModel.aircraft)
                    .disabled(self.flightModel.mode == .edit)
                HStack {
                    Text("Departure Date").standardFieldLabel()
                    DatePicker("", selection: $flightModel.scheduledDepartureDate)
                }
                if self.flightModel.mode == .create {
                    HStack {
                        VStack {
                            AirportField(labelText: "Departure", icao: $flightModel.origin)
                            AirportField(labelText: "Destination", icao: $flightModel.destination)
                        }
                        Button(action: swapAirports){
                            Image(systemName: "arrow.up.arrow.down")
                                .resizable()
                                .frame(width: 20,height: 20)
                        }
                    }
                }else{
                    AirportField(labelText: "Departure", icao: $flightModel.origin)
                    AirportField(labelText: "Destination", icao: $flightModel.destination)
                }
                HStack {
                    Text("Gate")
                        .standardFieldLabel()
                    TextField("Gate", text: $flightModel.gate)
                        .standardStyle()
                }
                HStack {
                    Text("Flight Number")
                        .standardFieldLabel()
                    TextField("Flight Number", text: $flightModel.flightNumber)
                        .standardStyle()
                    
                }
            }
            .padding(.horizontal)
        
            if isEnabled {
                StandardEditButtons(mode: self.flightModel.mode,
                                    submit: self.flightModel.submitText,
                                    delete: "Delete",
                                    submitAction: scheduleOrAmend,
                                    deleteAction: delete)
                if self.ticketListViewModel.tickets.count > 0 {
                    List() {
                        Section("Tickets") {
                            ForEach(self.ticketListViewModel.tickets) { ticket in
                                NavigationLink(value: ticket){
                                    TicketRowView(ticket: ticket)
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        
        .onAppear() {
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
    func swapAirports() {
        let save = self.flightModel.origin
        self.flightModel.origin = self.flightModel.destination
        self.flightModel.destination = save
        NotificationCenter.default.post(name: .airportSourceChanged, object: nil)
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
        let tickets = Samples.tickets
        Group {
            FlightEditView(flight: flights[0], mode: .edit, tickets: tickets, syncWithRemote: false)
            
            FlightEditView(flight: flights[0], mode: .create, tickets: [], syncWithRemote: false)
        }
    }
}
