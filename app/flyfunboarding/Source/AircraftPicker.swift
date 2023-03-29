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


struct AircraftPicker: View {
    @StateObject private var matchedAircrafts = MatchedAircraft()
    @Binding var aircraft : Aircraft
    @State var search : String = ""
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("Aircraft Registration")
                    .standardFieldLabel()
                TextField("Search", text: $search )
                    .standardStyle()
                    .onChange(of: search) { newValue in
                        matchedAircrafts.autocomplete(newValue)
                    }
            }
            List(matchedAircrafts.suggestions) { suggestion in
                VStack(alignment: .leading) {
                    AircraftRowView(aircraft: suggestion)
                }
                .onTapGesture {
                    self.aircraft = suggestion
                    self.dismiss()
                }
            }
        }
        .onAppear() {
            self.search = self.aircraft.registration
            self.matchedAircrafts.retrieveAircrafts()
        }
    }
}

