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

class KnownAirports {
    
    struct AirportCoord : KDTreePoint, Hashable, Identifiable {
        internal static var dimensions: Int = 2
        var id: String { return self.ident }
        
        init(coord : CLLocationCoordinate2D){
            ident = ""
            name = ""
            latitude_deg = coord.latitude
            longiture_deg = coord.longitude
        }
        
        init(ident : String, name: String, latitude_deg : Double, longiture_deg : Double){
            self.ident = ident
            self.name = name
            self.latitude_deg = latitude_deg
            self.longiture_deg = longiture_deg
        }
        let ident : String
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
            return self.ident.lowercased().contains(lc) || self.name.lowercased().contains(lc)
        }
        
        func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
            return MKMapPoint(CLLocationCoordinate2D(latitude: latitude_deg, longitude: longiture_deg)).distance(to: MKMapPoint(to))
        }
    }
    let tree : KDTree<AirportCoord>
    let db : FMDatabase
    
    let timezoneShapeFile : RZShapeFile?
    
    init(db : FMDatabase){
        var points : [AirportCoord] = []
        if let res = db.executeQuery("SELECT ident,name,latitude_deg,longitude_deg FROM airports", withArgumentsIn: []){
            while( res.next() ){
                if let ident = res.string(forColumnIndex: 0),
                   let name = res.string(forColumnIndex: 1){
                    let lat = res.double(forColumnIndex: 2)
                    let lon = res.double(forColumnIndex: 3)
                    points.append(AirportCoord(ident: ident, name: name, latitude_deg: lat, longiture_deg: lon))
                }
            }
        }
        self.db = db
        self.tree = KDTree<AirportCoord>(values: points)
        if let path = Bundle.main.url(forResource: "combined-shapefile", withExtension: "shp")?.path {
            self.timezoneShapeFile = RZShapeFile(base: (path as NSString).deletingPathExtension)
        }else{
            self.timezoneShapeFile = nil
        }
            
    }
 
    func nearestIdent(coord : CLLocationCoordinate2D) -> String? {
        let found = tree.nearest(to: AirportCoord(coord: coord))
        return found?.ident
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
    
    func timezone(airport : AirportCoord) -> TimeZone? {
        var rv : TimeZone? = nil
        if let shapeFile = self.timezoneShapeFile {
            let index = shapeFile.indexSet(forShapeContaining: airport.coord)
            let tzvalues = shapeFile.values(for: index)
            if let first = tzvalues.first, let tzname = first["tzid"] as? String {
                rv = TimeZone(identifier: tzname)
            }
        }
        return rv
    }
}

