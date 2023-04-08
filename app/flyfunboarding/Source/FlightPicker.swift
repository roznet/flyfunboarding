//  MIT License
//
//  Created on 23/03/2023 for flyfunboarding
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

class MatchedFlight : ObservableObject {
    private var flights : [Flight] = []
    @Published var suggestions : [Flight] = []

    init(flights : [Flight]? = nil) {
        if let flights = flights {
            self.flights = flights
            self.suggestions = flights
        } else {
            self.flights = []
            self.suggestions = []
        }
    }

    func retrieveFlights() {
        RemoteService.shared.retrieveFlightList() { found in
            if let flights = found {
                DispatchQueue.main.async {
                    let ordered = flights.sorted(){
                        $0.moreRecent(than: $1)
                    }
                    self.flights = ordered
                    self.suggestions = ordered
                }
            }
        }
    }
    
}
struct FlightPicker: View {
    @StateObject var matchedFlight = MatchedFlight()
    @Binding var flight : Flight
    
    var completion : () -> Void = {}
    
    var body: some View {
        List(matchedFlight.suggestions) { flight in
            FlightRowView(flight: flight)
                .onTapGesture {
                    self.flight = flight
                    completion()
                }
        }
        .standardNavigationBarTitle("Choose Flight")
        .onAppear{
            self.matchedFlight.retrieveFlights()
        }
    }
}
