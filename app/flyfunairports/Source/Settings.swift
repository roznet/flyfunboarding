//  MIT License
//
//  Created on 09/09/2023 for flyfunairports
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
import RZUtilsSwift
import OSLog
import CoreLocation

struct Settings {
    static let shared = Settings()
    
    enum Key : String {
        case last_latitude = "last_latitude"
        case last_longitude = "last_longitude"
        case last_airport_ident = "last_airport_ident"
    }
  
    @UserStorage(key: Key.last_latitude, defaultValue: 51.50)
    var lastLatitude : Double
    @UserStorage(key: Key.last_longitude, defaultValue: 0.12)
    var lastLongitude : Double
    
    @UserStorage(key: Key.last_airport_ident, defaultValue: "EGTF")
    var lastAirportIdent : String
    
    var lastCoordinate : CLLocationCoordinate2D {
        get { return CLLocationCoordinate2D(latitude: self.lastLatitude, longitude: self.lastLongitude) }
        set { self.lastLatitude = newValue.latitude; self.lastLongitude = newValue.longitude }
    }
}
