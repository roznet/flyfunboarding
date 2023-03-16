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

struct FlightListView: View {
    @StateObject var flightListViewModel = FlightListViewModel(flights: [])
    var body: some View {
        NavigationStack {
            List(flightListViewModel.flights) { flight in
                NavigationLink(destination: FlightEditView(flightModel: FlightViewModel(flight:flight))) {
                    FlightRowView(flight: flight)
                }
            }.navigationTitle("Flights")
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button(action: add) {
                    VStack {
                        Image(systemName: "plus.circle")
                        Text("Add")
                    }
                }.padding()
                Button(action: delete) {
                    VStack {
                        Image(systemName: "minus.circle")
                        Text("Delete")
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            flightListViewModel.retrieveFlights()
        }
    }
    func add() {
        
    }
    func delete() {
        
    }
}

struct FlightListView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = Samples.flights
        FlightListView(flightListViewModel: FlightListViewModel(flights: sample, syncWithRemote: false))
    }
}
