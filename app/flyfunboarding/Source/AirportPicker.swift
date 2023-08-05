//  MIT License
//
//  Created on 29/03/2023 for flyfunboarding
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
import CoreLocation
import RZFlight
import OSLog

extension Notification.Name {
    static let airportWasPicked = Notification.Name("airportWasPicked")
}
struct AirportPicker: View {
    
    @StateObject var matchedAiports = MatchedAirport()
    @Binding var icao : String
    @State var search :String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("Search Airport")
                TextField("Search", text: $search)
                    .standardStyle()
                    .onChange(of: search){ newValue in
                        self.matchedAiports.autocomplete(newValue)
                    }
                    .onAppear(){
                        self.matchedAiports.autocomplete(search)
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
            }
            .padding([.leading,.trailing])
            List(matchedAiports.suggestions) { suggestion in
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(suggestion.icao).font(.headline)
                        Spacer()
                        Text(self.formatDistance(suggestion: suggestion)).font(.footnote).foregroundColor(.secondary).padding(.trailing)
                    }
                    Text(suggestion.name).font(.footnote)
                }.onTapGesture {
                    self.icao = suggestion.icao
                    NotificationCenter.default.post(name: .airportWasPicked, object: nil)
                    self.dismiss()
                    
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    func formatDistance(suggestion : Airport) -> String{
        let dist = suggestion.distance(to: matchedAiports.coord)
        let measure = Measurement(value: dist, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(for: measure) ?? ""
        
    }
}
