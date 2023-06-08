//  MIT License
//
//  Created on 15/03/2023 for flyfunboarding
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
    static let aircraftModified = Notification.Name("aicraftModified")
}

struct AircraftEditView: View {
    @StateObject var aircraftModel : AircraftViewModel
    @StateObject var flightListViewModel : FlightListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var editIsDisabled : Bool = false
    @State var isPresentingConfirm : Bool = false
    
    init(aircraft: Aircraft, mode : AircraftViewModel.Mode,
         flights: [Flight] = [], syncWithRemote: Bool = true) {
        _aircraftModel = StateObject(wrappedValue: AircraftViewModel(aircraft: aircraft, mode: mode))
        _flightListViewModel = StateObject(wrappedValue: FlightListViewModel(flights: flights, aircraft: aircraft, syncWithRemote: syncWithRemote))
        
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(NSLocalizedString("Registration", comment: "Aircraft"))
                    .standardFieldLabel()
                TextField("Registration", text: $aircraftModel.registration)
                    .standardStyle()
                    .withClearButton()
            }
            .padding([.trailing,.leading])
            HStack {
                Text(NSLocalizedString("Type", comment: "Aircraft"))
                    .standardFieldLabel()
                TextField("Type", text: $aircraftModel.type)
                    .standardStyle()
                    .withClearButton()
                    
            }
            .padding([.trailing,.leading])
            if !self.editIsDisabled {
                StandardEditButtons(mode: self.aircraftModel.mode,
                                    submit: self.aircraftModel.submitText,
                                    delete: "Delete",
                                    submitAction: save,
                                    deleteAction: cancel)
                if self.flightListViewModel.flights.count > 0 {
                    VStack {
                        List() {
                            Section("Flights"){
                                ForEach(self.flightListViewModel.flights) { flight in
                                    NavigationLink(value: flight){
                                        FlightRowView(flight: flight)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
        }.padding(.bottom)
            .onAppear {
                self.flightListViewModel.retrieveFlights()
            }
    }
    func flightEditView(flight: Flight) -> some View {
        return FlightEditView(flight:flight, mode: .edit)
    }
    func cancel() {
        RemoteService.shared.deleteAircraft(aircraft: self.aircraftModel.aircraft) {
            success in
            if success {
                DispatchQueue.main.async {
                    dismiss()
                }
            }
        }
    }

    func save() {
        Logger.ui.info("Save Aircraft \(self.aircraftModel.aircraft)")
        RemoteService.shared.registerAircraft(aircraft: self.aircraftModel.aircraft){
            a in
            if let a = a{
                Logger.ui.info("Save success \(a)")
                NotificationCenter.default.post(name: .aircraftModified, object: nil)
                DispatchQueue.main.async {
                    self.aircraftModel.aircraft = a
                    self.aircraftModel.mode = .edit
                }
            }else{
                Logger.ui.error("Failed to save aircraft")
            }
        }
    }
}


struct AircraftView_Previews: PreviewProvider {
    static var previews: some View {
        AircraftEditView(aircraft: Samples.aircraft, mode: .edit, syncWithRemote: false)
    }
}
