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
import CoreLocation
import RZFlight
import OSLog

class MatchedAirport : ObservableObject {
    class LocationRequest : NSObject, CLLocationManagerDelegate {
        var locationManager : CLLocationManager = CLLocationManager()
        var cb : (CLLocationCoordinate2D) -> Void = { _ in }
        
        func start(cb : @escaping (CLLocationCoordinate2D) -> Void) {
            locationManager.delegate = self
            self.cb = cb
            self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
            self.locationManager.requestWhenInUseAuthorization()
            locationManager.requestLocation()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let first = locations.first else { return }
            cb(first.coordinate)
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            Logger.ui.info("Failed to get location, ignoring \(error.localizedDescription)")
        }
    }
    
    typealias AirportCoord = KnownAirports.AirportCoord
    
    @Published var suggestions : [AirportCoord] = []
    var coord = CLLocationCoordinate2D(latitude: 51.50, longitude: 0.12)
    private var locationRequest : LocationRequest = LocationRequest()
    private var lastText : String? = nil
    
    init() {
        self.coord = CLLocationCoordinate2D(latitude: Settings.shared.lastLatitude,
                                            longitude: Settings.shared.lastLongitude)
        self.locationRequest.start() {
            c in
            self.coord = c
            Settings.shared.lastLatitude = c.latitude
            Settings.shared.lastLongitude = c.longitude
            if let text = self.lastText {
                self.autocomplete(text)
            }
        }
    }
   
    private var searching : Bool = false
    
    func shouldAutocomplete(_ text : String) -> Bool {
        /*if suggestions.count == 1 && suggestions.first!.ident == text {
            return false
        }*/
        return true
    }
    
    func autocomplete(_ text : String) {
        DispatchQueue.synchronized(self){
            guard !self.searching else { return }
            self.searching = true
        }
        
        FlyFunBoardingApp.worker.async {
            if let found = FlyFunBoardingApp.knownAirports?.nearestDescriptions(coord: self.coord, needle: text, count: 20) {
                DispatchQueue.main.async {
                    DispatchQueue.synchronized(self){
                        self.lastText = text
                        self.suggestions = found
                        self.searching = false
                    }
                }
            }else{
                self.searching = false
            }
        }
    }
}
struct AirportPicker: View {
    @StateObject var matchedAiports = MatchedAirport()
    var labelText : String
    @Binding var icao : String
    @State var name : String
    @State private var showPopup = false
    @FocusState var isFocused : Bool
    @State var editIsDisabled : Bool = false
    
    func sync() {
        if let name = Airport.find(icao: self.icao) {
            self.name = name.name
        }else{
            self.name = ""
        }
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text(self.labelText)
                VStack {
                    TextField("ICAO", text: $icao)
                        .standardStyle()
                        .disabled(editIsDisabled)
                        .focused($isFocused)
                        .onChange(of: icao) { newValue in
                            if matchedAiports.shouldAutocomplete(newValue) {
                                matchedAiports.autocomplete(newValue)
                            }
                        }
                        .onTapGesture {
                            self.showPopup = true
                            matchedAiports.autocomplete(self.icao)
                        }
                        .onChange(of: isFocused){ isFocused in
                            if isFocused {
                                Logger.ui.info("focused")
                                self.showPopup = true
                                
                            }else{
                                Logger.ui.info("not focused")
                                self.showPopup = false
                            }
                        }
                    Text(name)
                        .font(.footnote)
                        .onAppear() { self.sync() }
                }
            }
            
            if showPopup && !editIsDisabled {
                List(matchedAiports.suggestions, id: \.self) { suggestion in
                    VStack(alignment: .leading) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(suggestion.ident).font(.headline)
                            Spacer()
                            Text(self.formatDistance(suggestion: suggestion)).font(.footnote).foregroundColor(.secondary).padding(.trailing)
                        }
                        Text(suggestion.name).font(.footnote)
                    }.onTapGesture {
                        self.icao = suggestion.ident
                        self.name = suggestion.name
                        self.showPopup = false
                    }
                }
                .listStyle(.insetGrouped)
                .frame(minHeight: 320.0)
            }
        }
    }
    
    func formatDistance(suggestion : MatchedAirport.AirportCoord) -> String{
        let dist = suggestion.distance(to: matchedAiports.coord)
        let measure = Measurement(value: dist, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(for: measure) ?? ""
        
    }
}

struct AirportPicker_Previews: PreviewProvider {
    static var previews: some View {
        AirportPicker(labelText: "Destination", icao: .constant("EGTF"), name: "Fairoaks")
    }
}
