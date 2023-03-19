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
import OSLog

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
        }
    }
    func retrieveAircrafts() {
        RemoteService.shared.retrieveAircraftList() { found in
            if let aircrafts = found {
                DispatchQueue.main.async {
                    self.aircrafts = aircrafts
                    self.suggestions = aircrafts
                }
            }
        }
    }
    func shouldAutocomplete(_ text : String) -> Bool {
        return true
    }
    func autocomplete(_ text : String) {
        self.suggestions = aircrafts.sorted {
            $0.registration.score(word: text) > $1.registration.score(word: text)
        }
    }
}
struct AircraftPicker: View {
    @StateObject private var matchedAircrafts = MatchedAircraft()
    @Binding var aircraftRegistration : String
    @State private var showPopup : Bool = false
    @FocusState private var isFocused : Bool
    @State var editIsDisabled : Bool = false

    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("Aircraft Registration")
                    .standardFieldLabel()
                TextField("Registration", text: $aircraftRegistration )
                    .standardStyle()
                    .disabled(self.editIsDisabled)
                    .focused($isFocused)
                    .onChange(of: aircraftRegistration) { newValue in
                        self.showPopup = true
                        matchedAircrafts.autocomplete(newValue)
                    }
                    .onTapGesture {
                        self.showPopup = true
                        self.matchedAircrafts.autocomplete(self.aircraftRegistration)
                    }
                    .onChange(of: isFocused) { isFocused in
                        showPopup = isFocused
                        self.matchedAircrafts.retrieveAircrafts()
                    }
            }
        }
        if showPopup {
            VStack {
                List(matchedAircrafts.suggestions) { aircraft in
                    AircraftRowView(aircraft: aircraft)
                        .onTapGesture {
                            self.aircraftRegistration = aircraft.registration
                            self.showPopup = false
                        }
                }
            }
        }
    }
}

struct AircraftPicker_Previews: PreviewProvider {
    static var previews: some View {
        //let aircrafts = Samples.aircrafts
        AircraftPicker(aircraftRegistration: .constant("N122DR"))
    }
}
