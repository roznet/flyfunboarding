//
//  AirlineViewModel.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
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
