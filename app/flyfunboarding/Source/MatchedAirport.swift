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
import OSLog


class MatchedAirport : ObservableObject {
    class LocationRequest : NSObject, CLLocationManagerDelegate {
        var locationManager : CLLocationManager = CLLocationManager()
        var cb : (CLLocationCoordinate2D) -> Void = { _ in }
        
        func start(callback : @escaping (CLLocationCoordinate2D) -> Void) {
            locationManager.delegate = self
            self.cb = callback
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
    
    var coord : CLLocationCoordinate2D
    private var locationRequest : LocationRequest = LocationRequest()
    
    init() {
        self.coord = CLLocationCoordinate2D(latitude: Settings.shared.lastLatitude,
                                            longitude: Settings.shared.lastLongitude)
        self.locationRequest.start() {
            c  in
            self.coord = c
            Settings.shared.lastLatitude = c.latitude
            Settings.shared.lastLongitude = c.longitude
        }
    }
    
    private var searching : Bool = false
    
    func autocomplete(_ text : String) {
        DispatchQueue.synchronized(self){
            guard !self.searching else { return }
            self.searching = true
        }
        
        FlyFunBoardingApp.worker.async {
            if let found = FlyFunBoardingApp.knownAirports?.nearestDescriptions(coord: self.coord, needle: text, count: 20) {
                DispatchQueue.main.async {
                    DispatchQueue.synchronized(self){
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
