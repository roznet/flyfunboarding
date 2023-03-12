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


import Foundation

class AirlineViewModel : ObservableObject {
    @Published var airline : Airline
    
    var airlineName : String {
        get { return self.airline.airlineName }
        set {
            if newValue != self.airline.airlineName {
                self.airline = Airline(airlineName: newValue, appleIdentifier: self.airline.appleIdentifier, airlineId: self.airline.airlineId)
            }
        }
    }
    var appleIdentifier : String {
        get { return self.airline.appleIdentifier }
        set {
            if newValue != self.airline.appleIdentifier {
                self.airline = Airline(airlineName: self.airline.airlineName, appleIdentifier: newValue, airlineId: self.airline.airlineId)
            }
        }
    }
   
    init(airline : Airline) {
        self.airline = airline
    }
    
    init() {
        airline = Settings.shared.currentAirline ?? Airline()
        RemoteService.shared.retrieveCurrentAirline() {
            airline in
            if let airline = airline {
                DispatchQueue.main.async {
                    self.airline = airline
                }
            }
        }
    }
    
    func updateAirline(){
        RemoteService.shared.registerAirline(airline: airline) {
            found in
            if let found = found {
                DispatchQueue.main.async {
                    self.airline = found
                }
            }
        }
    }
}
