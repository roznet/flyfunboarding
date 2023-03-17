//  MIT License
//
//  Created on 17/03/2023 for flyfunboarding
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

class MatchedAircraft : ObservableObject {
    private var aircrafts : [Aircraft] = []
    @Published var suggestions : [Aircraft] = []
   
    init(aircrafts : [Aircraft]? = nil) {
        if let aircrafts = aircrafts {
            self.aircrafts = aircrafts
            self.suggestions = aircrafts
        } else {
            self.aircrafts = []
            self.suggestions = []
            RemoteService.shared.retrieveAircraftList() { found in
                if let aircrafts = found {
                    DispatchQueue.main.async {
                        self.aircrafts = aircrafts
                        self.suggestions = aircrafts
                    }
                }
            }
        }
    }
    func shouldAutocomplete(_ text : String) -> Bool {
        if suggestions.count == 1 && suggestions.first!.registration == text {
            return false
        }
        return true
    }
    func autocomplete(_ text : String) {
        for aircraft in aircrafts {
            var found : [Aircraft] = []
            if aircraft.registration.contains(text) {
                found.append(aircraft)
            }
            self.suggestions = found
        }
    }
}

struct AircraftPicker: View {
    @ObservedObject private var matchedAircrafts : MatchedAircraft
    @State private var selectedAircraftRegistration : String
    @State private var showPopup : Bool = false

    init(registration: String, aircrafts: [Aircraft]? = nil) {
        self.selectedAircraftRegistration = registration
        self.matchedAircrafts = MatchedAircraft(aircrafts: aircrafts)
    }


    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("Aircraft Registration")
                TextField("Registration", text: $selectedAircraftRegistration )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: selectedAircraftRegistration) { newValue in
                        if matchedAircrafts.shouldAutocomplete(newValue) {
                            matchedAircrafts.autocomplete(newValue)
                        }
                    }
                    .onTapGesture {
                        self.showPopup = true
                    }
            }
        }
        if showPopup {
            VStack {
                List(matchedAircrafts.suggestions, id: \.self) { aircraft in
                    AircraftRowView(aircraft: aircraft)
                        .onTapGesture {
                            self.selectedAircraftRegistration = aircraft.registration
                            self.showPopup = false
                        }
                }
            }
        }
    }
}

struct AircraftPicker_Previews: PreviewProvider {
    static var previews: some View {
        let aircrafts = Samples.aircrafts
        AircraftPicker(registration: "N", aircrafts: aircrafts)
    }
}
