//  MIT License
//
//  Created on 08/09/2023 for flyfunairports
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
import MapKit
import OSLog
import RZFlight

struct MapView: View {
    @State var airport : Airport? = nil
    @State var showAirports : [Airport] = []
    @State var region : MKCoordinateRegion = MKCoordinateRegion()
    var body: some View {
        VStack {
            if let airport = self.airport {
                Map(interactionModes: .all) {
                    Annotation("EGTF", coordinate: airport.coord) {
                        ZStack {
                            AirportIcon(airport: airport)
                                .frame(width: 50,height: 50)
                        }
                    }
                    ForEach( self.showAirports ) { one in
                        Annotation(one.icao, coordinate: one.coord) {
                            ZStack {
                                AirportIcon(airport: one)
                                    .frame(width: 50, height: 50)
                                    .onTapGesture {
                                        Logger.app.info("Tapped \(one)")
                                    }
                            
                            }
                            
                        }
                    }
                }
                .mapControlVisibility(.visible)
                
            }else {
                Text("hi")
            }
        }.onAppear() {
            FlyFunAirportsApp.worker.async {
                NotificationCenter.default.addObserver(forName: .airportLoaded, object: nil, queue: nil){ _ in
                    let found = FlyFunAirportsApp.knownAirports?.airport(icao: Settings.shared.lastAirportIdent, ensureRunway: true)
                    self.changeAirport(airport: found)
                }
                let found = FlyFunAirportsApp.knownAirports?.airport(icao: Settings.shared.lastAirportIdent, ensureRunway: true)
                self.changeAirport(airport: found)
            }
        }
    }
    
    func changeAirport(airport : Airport?) {
        if let airport = airport {
            DispatchQueue.main.async {
                self.airport = airport
                self.region = MKCoordinateRegion(center: airport.coord, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            }
            FlyFunAirportsApp.worker.async {
                if let ppf = FlyFunAirportsApp.knownAirports?.frenchPPL() {
                    DispatchQueue.main.async {
                        self.showAirports = ppf
                    }
                }
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
