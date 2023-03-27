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
import OSLog
import RZUtilsSwift
import AuthenticationServices
import FMDB
import RZFlight
import RZExternalUniversal

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

@main
struct FlyFunBoardingApp: App {
    static public var knownAirports : KnownAirports? = nil
    public static let worker = DispatchQueue(label: "net.ro-z.flightlogstats.worker")
    public static var db : FMDatabase = FMDatabase()
    public static var timezoneShapeFile : RZShapeFile? = nil

    init() {
        Secrets.shared = Secrets(url: Bundle.main.url(forResource: "secrets", withExtension: "json"))
        FlyFunBoardingApp.db = FMDatabase(url: Bundle.main.url(forResource: "airports", withExtension: "db"))
        FlyFunBoardingApp.db.open()
        FlyFunBoardingApp.worker.async {
            FlyFunBoardingApp.knownAirports = KnownAirports(db: FlyFunBoardingApp.db)
            if let path = Bundle.main.url(forResource: "combined-shapefile", withExtension: "shp")?.path {
                FlyFunBoardingApp.timezoneShapeFile = RZShapeFile(base: (path as NSString).deletingPathExtension)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
    
}
