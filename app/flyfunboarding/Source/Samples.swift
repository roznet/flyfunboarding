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

class Samples {
    private static func object<Type : Codable>(resource : String) -> Type? {
        if let url = Bundle.main.url(forResource: resource, withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let rv = try RemoteService.decoder.decode(Type.self, from: data)
                
                return rv
            }catch{
                Logger.app.error("failed to parse \(error)")
            }
        }
        return nil
    }
    
    private static func array<Type : Codable>(resource : String) -> [Type] {
        if let url = Bundle.main.url(forResource: resource, withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let rv = try RemoteService.decoder.decode([Type].self, from: data)
                return rv
            }catch{
                Logger.app.error("failed to parse \(error)")
            }
        }
        return []
    }
    
    static var aircrafts : [Aircraft] {
        return self.array(resource: "sample_aircrafts")
    }
    
    static var aircraft : Aircraft {
        return self.aircrafts[0]
    }
    
    static var airline : Airline? {
        return self.object(resource: "sample_airline")
    }
    
    static var passengers : [Passenger] {
        return self.array(resource: "sample_passengers")
    }
    static var flights : [Flight] {
        return self.array(resource: "sample_flights")
    }
    static var tickets : [Ticket] {
        return self.array(resource: "sample_tickets")
    }
}
