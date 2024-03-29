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



import Foundation
import SwiftUI

struct AircraftRowView : View {
    var aircraft : Aircraft
    var selected : Bool = false
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(aircraft.registration).standardFieldLabel()
                Text(aircraft.type).standardFieldValue()
            }.padding(.leading)
            Spacer()
            if let first = aircraft.stats?.first {
                StatsView(stats: first)
            }
            if self.selected {
                Image(systemName: "checkmark.circle").padding(.trailing)
            }
        }.padding(.bottom)
    }
}

struct AircraftRowView_Previews: PreviewProvider {
    static func aircraftWithStats(aircraft : Aircraft) -> Aircraft {
        let rv = aircraft
        rv.stats = [Stats(table: "Flights", count: 2, last: Date() )]
        return rv
    }
    
    static var previews: some View {
        let aircrafts = Samples.aircrafts
        let withStats : Aircraft = self.aircraftWithStats(aircraft: aircrafts[0])
        List {
            AircraftRowView(aircraft: aircrafts[0])
            AircraftRowView(aircraft: withStats)
            AircraftRowView(aircraft: aircrafts[1], selected: true)
        }
    }
}
