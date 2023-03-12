//  MIT License
//
//  Created on 12/03/2023 for flyfunboarding
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
import RZFlight
import RZData
import CoreLocation

class MatchedAirport : ObservableObject {
    typealias AirportCoord = KnownAirports.AirportCoord
    
    @Published var suggestions : [AirportCoord] = []
    private var coord = CLLocationCoordinate2D(latitude: 51.50, longitude: 0.12)
   
    private var searching : Bool = false
    
    func autocomplete(_ text : String) {
        DispatchQueue.synchronized(self){
            guard self.searching else { return }
            self.searching = true
        }
        
        FlyFunBoardingApp.worker.async {
            if let found = FlyFunBoardingApp.knownAirports?.nearestDescriptions(coord: self.coord, needle: text, count: 20) {
                DispatchQueue.main.async {
                    DispatchQueue.synchronized(self){
                        self.suggestions = found
                        self.searching = true
                    }
                }
            }else{
                self.searching = false
            }
        }
    }
}
struct FlightListView: View {
    @State private var flightDate = Date.now
    @State private var departureAirport = "EGTF"
    @State private var departureDescription = "Fairoaks"
    @ObservedObject private var matchedAiports = MatchedAirport()
    var body: some View {
        VStack {
            DatePicker("Flight Departure", selection: $flightDate)
            HStack(alignment: .firstTextBaseline) {
                Text("Departure Airport")
                VStack {
                    TextField("ICAO Name", text: $departureAirport).textFieldStyle(.roundedBorder)
                        .onChange(of: departureAirport){ newValue in
                            matchedAiports.autocomplete(newValue)
                        }
                    Text(departureDescription).font(.footnote)
                }
            }
            List(matchedAiports.suggestions, id: \.self) { suggestion in
                ZStack {
                    Text("\(suggestion.ident) - \(suggestion.name)")
                }.onTapGesture {
                    self.departureAirport = suggestion.ident
                    self.departureDescription = suggestion.name
                }
            }
        }
    }
}

struct FlightListView_Previews: PreviewProvider {
    static var previews: some View {
        FlightListView()
    }
}
