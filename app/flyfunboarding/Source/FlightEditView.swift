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

struct FlightEditView: View {
    @StateObject var flightModel : FlightViewModel
    @Environment(\.dismiss) var dismiss
    @State var editIsDisabled : Bool = false
    
    var body: some View {
        VStack {
            AircraftPicker(aircraftRegistration: $flightModel.aircraftRegistration)
                .disabled(self.editIsDisabled)
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
                TextField("Gate", text: $flightModel.flightNumber)
                    .standardStyle()
                    .disabled(self.editIsDisabled)
                    
            }
            if !self.editIsDisabled {
                Button("Schedule", action: schedule)
                    .standardButton()
            }
            Spacer()
        }
        
    }
    func schedule() {
        let newFlight = self.flightModel.flight
        RemoteService.shared.scheduleFlight(flight: newFlight){
            f in
            if let f = f {
                Logger.ui.info( "Scheduled \(f)")
            }else{
                Logger.ui.error("Failed to schedule flight")
            }
            DispatchQueue.main.async {
                //dismiss()
            }
        }
    }
}

struct FlightEditView_Previews: PreviewProvider {
    static var previews: some View {
        let flights = Samples.flights
        FlightEditView(flightModel: FlightViewModel(flight: flights[0]), editIsDisabled: false)
    }
}
