//  MIT License
//
//  Created on 16/09/2023 for flyfunairports
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
import MapKit
import OSLog
import RZFlight

class LocationSearch : NSObject, ObservableObject, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    let manager = CLLocationManager()
    @Published var region : MKCoordinateRegion
    @Published var location : CLLocationCoordinate2D
    
    @Published var searchText : String = "" {
        didSet {
            self.update()
        }
    }
    
    let searchCompleter : MKLocalSearchCompleter
    @Published var searchResults : [ MKLocalSearchCompletion] = []
    @Published var airportResults : [Airport] = []
    
    override init() {
        let lastCoord = Settings.shared.lastCoordinate
        self.location = lastCoord
        self.region = MKCoordinateRegion(center: lastCoord, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        self.searchCompleter = MKLocalSearchCompleter()
        super.init()
        
        self.searchCompleter.delegate = self
        self.searchCompleter.region = self.region
    }
    
    func update(search : String? = nil) {
        if let search = search {
            self.searchText = search
        }
        if self.searchText.isEmpty {
            return
        }
        if self.searchCompleter.isSearching {
            self.searchCompleter.cancel()
        }
        self.searchCompleter.queryFragment = self.searchText
        FlyFunAirportsApp.worker.async {
            if let found = FlyFunAirportsApp.knownAirports?.nearestMatching(coord: self.location, needle: self.searchText, count: 10) {
                DispatchQueue.main.async {
                    self.airportResults = found
                }
            }else {
                self.airportResults = []
            }
            
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
        Logger.app.info("Search Completion")
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Logger.app.error("Failed to complete \(error)")
    }
        
}
