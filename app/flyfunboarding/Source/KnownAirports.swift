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
import FMDB
import KDTree
import CoreLocation
import RZFlight
import RZExternalUniversal
import MapKit

extension Airport {
    static func find(icao : String) -> Airport? {
        return try? Airport(db: FlyFunBoardingApp.db, ident: icao)
    }
}

extension TimeZone {
    static func find(icao : String) -> TimeZone? {
        var rv : TimeZone? = nil
        if let shapeFile = FlyFunBoardingApp.timezoneShapeFile,
           let airport = Airport.find(icao: icao) {
            let index = shapeFile.indexSet(forShapeContaining: airport.coord)
            let tzvalues = shapeFile.values(for: index)
            if let first = tzvalues.first, let tzname = first["tzid"] as? String {
                rv = TimeZone(identifier: tzname)
            }
        }
        return rv
    }
}

class KnownAirports {
    
    struct AirportCoord : KDTreePoint, Hashable, Identifiable {
        internal static var dimensions: Int = 2
        var id: String { return self.icao }
        
        init(coord : CLLocationCoordinate2D){
            icao = ""
            name = ""
            latitude_deg = coord.latitude
            longiture_deg = coord.longitude
        }
        
        init(icao : String, name: String, latitude_deg : Double, longiture_deg : Double){
            self.icao = icao
            self.name = name
            self.latitude_deg = latitude_deg
            self.longiture_deg = longiture_deg
        }
        let icao : String
        let name : String
        let latitude_deg : Double
        let longiture_deg : Double
        
        var coord : CLLocationCoordinate2D { return CLLocationCoordinate2D(latitude: self.latitude_deg, longitude: self.longiture_deg)}
        
        func kdDimension(_ dimension: Int) -> Double {
            if dimension == 0 {
                return latitude_deg
            }else{
                return longiture_deg
            }
        }
        func squaredDistance(to otherPoint: KnownAirports.AirportCoord) -> Double {
            let lat = (latitude_deg-otherPoint.latitude_deg)
            let lon = (longiture_deg-otherPoint.longiture_deg)
            return lat*lat+lon*lon
        }
        
        func matches(_ needle : String) -> Bool {
            let lc = needle.lowercased()
            return self.icao.lowercased().contains(lc) || self.name.lowercased().contains(lc)
        }
        
        func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
            return MKMapPoint(CLLocationCoordinate2D(latitude: latitude_deg, longitude: longiture_deg)).distance(to: MKMapPoint(to))
        }
    }
    let tree : KDTree<AirportCoord>
    let db : FMDatabase
    
    
    init(db : FMDatabase){
        var points : [AirportCoord] = []
        if let res = db.executeQuery("SELECT ident,name,latitude_deg,longitude_deg FROM airports", withArgumentsIn: []){
            while( res.next() ){
                if let ident = res.string(forColumnIndex: 0),
                   let name = res.string(forColumnIndex: 1){
                    let lat = res.double(forColumnIndex: 2)
                    let lon = res.double(forColumnIndex: 3)
                    points.append(AirportCoord(icao: ident, name: name, latitude_deg: lat, longiture_deg: lon))
                }
            }
        }
        self.db = db
        self.tree = KDTree<AirportCoord>(values: points)
        
            
    }
 
    func nearestIdent(coord : CLLocationCoordinate2D) -> String? {
        let found = tree.nearest(to: AirportCoord(coord: coord))
        return found?.icao
    }
    func nearest(coord : CLLocationCoordinate2D, db : FMDatabase) -> Airport? {
        if let found = self.nearestIdent(coord: coord){
            return try? Airport(db: db, ident: found)
        }
        return nil
    }
    func nearestDescriptions(coord : CLLocationCoordinate2D, needle: String, count : Int) -> [AirportCoord] {
        return tree.nearestK(count, to: AirportCoord(coord: coord)) { $0.matches(needle) }
    }
    

}

