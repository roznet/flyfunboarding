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
import OSLog
import SwiftUI


class AirlineViewModel : ObservableObject {
    @Published var airline : Airline
    @Published var bgColor = Color(red: 189.0/255.0, green: 144.0/255.0, blue: 71.0/255.0)
    @Published var labelColor = Color(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0)
    @Published var textColor = Color(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0)
    @Published var customLabelEnabled : Bool = false
    @Published var customLabel : String = "Boarding Group"

    var airlineName : String {
        get { return self.airline.airlineName }
        set {
            if newValue != self.airline.airlineName {
                self.airline = self.airline.with(newName: newValue)
            }
        }
    }
    var appleIdentifier : String {
        get { return self.airline.appleIdentifier }
    }
    
    var settings : Airline.Settings {
        get {
            return Airline.Settings(backgroundColor: self.bgColor,
                                    foregroundColor: self.textColor,
                                    labelColor: self.labelColor,
                                    customLabel: self.customLabel,
                                    customLabelEnabled: self.customLabelEnabled)
        }
        set {
            self.bgColor = newValue.backgroundColor
            self.textColor = newValue.foregroundcolor
            self.labelColor = newValue.labelColor
            self.customLabel = newValue.customLabel
            self.customLabelEnabled = newValue.customLabelEnabled
        }
    }
    
   
    init(airline : Airline) {
        self.airline = airline
        self.retrieveSettings()
    }
    
    init() {
        airline = Settings.shared.currentAirline ?? Airline()
        RemoteService.shared.retrieveCurrentAirline() {
            airline in
            if let airline = airline, let airlineIdentifier = airline.airlineIdentifier {
                Logger.net.info("Retrieved airline \(airlineIdentifier)")
                DispatchQueue.main.async {
                    self.airline = airline
                    RemoteService.shared.retrieveAndCheckCurrentAirlineKeys()
                    self.retrieveSettings()
                }
            }else{
                Logger.net.error("Failed to retrieved current Airline")
                Settings.shared.currentAirline = nil
            }
        }
    }
    
    func retrieveSettings() {
        RemoteService.shared.retrieveAirlineSettings() {
            settings in
            if let settings = settings {
                DispatchQueue.main.async {
                    self.settings = settings
                    Settings.shared.currentAirlineSettings = settings
                }
            }
        }
    }
   
    func settingsChanged() {
        Logger.ui.info("Settings changed")
        let settings = self.settings
        
        RemoteService.shared.updateAirlineSettings(settings: settings) {
            got in
            if let got = got {
                Settings.shared.currentAirlineSettings = got
                Logger.net.info("Updated settings \(got)")
            }else{
                Logger.net.error("Failed to update settings")
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
