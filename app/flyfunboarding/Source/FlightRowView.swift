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

struct FlightRowView: View {
    var flight : Flight
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack {
                    Text(flight.origin.icao).standardFieldLabel()
                    Image(systemName: "arrow.right")
                    Text(flight.destination.icao).standardFieldLabel()
                }
                Spacer()
                Text(flight.scheduledDepartureDate, style: .date)
            }
            HStack {
                Text(flight.aircraft.registration).standardFieldValue()
                Spacer()
                Text(flight.scheduledDepartureDate, style: .time)
            }
            if let first = flight.stats?.first {
                HStack {
                    Spacer()
                    Text(first.formattedCount).standardInfo()
                }
            }
            
        }.padding(.bottom)
    }
}

struct FlightRowView_Previews: PreviewProvider {
    static var previews: some View {
        let flights = Samples.flights
        List {
            FlightRowView(flight: flights[0])
            FlightRowView(flight: flights[1])
        }
    }
}
