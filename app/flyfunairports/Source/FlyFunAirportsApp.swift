//  MIT License
//
//  Created on 08/09/2023 for flyfunairports
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
import RZFlight
import FMDB
import RZExternalUniversal
extension Airport {
    static func find(icao : String) -> Airport? {
        return try? Airport(db: FlyFunAirportsApp.db, ident: icao)
    }
}
@main
struct FlyFunAirportsApp : App {
    static public var knownAirports : KnownAirports? = nil
    public static let worker = DispatchQueue(label: "net.ro-z..worker")
    
    public static var db : FMDatabase = FMDatabase()
    public static var timezoneShapeFile : RZShapeFile? = nil
    
    init() {
        FlyFunAirportsApp.db = FMDatabase(url: Bundle.main.url(forResource: "airports", withExtension: "db"))
        FlyFunAirportsApp.db.open()
        FlyFunAirportsApp.worker.async {
            FlyFunAirportsApp.knownAirports = KnownAirports(db: FlyFunAirportsApp.db)
        }
    }
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}