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
import RZFlight
import FMDB
extension Airport {
    var displayHeadings : [Int] {
        var headings : [Int] = []
        for runway in self.runways {
            let h1 : Int = Int(runway.trueHeading1.heading)
            let h2 : Int = Int(runway.trueHeading2.heading)
            if( !headings.contains(h1)) {
                headings.append(h1)
                headings.append(h2)
            }
        }
        return headings
    }
}
struct AirportIcon: View {
    let airport : Airport
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height)
            let half = width
            let runwayStroke = max(1.0, width * 0.15)
            let circleStroke = max(1.0, width * 0.1)
            let outer = half * 0.8
            let inner = half * 0.5
            let center = CGPoint(x: geometry.size.width * 0.5,
                                 y: geometry.size.height * 0.5 )
            let headings = airport.displayHeadings
            ZStack {
                Circle()
                    .strokeBorder(Color.blue,lineWidth: circleStroke)
                    .fill(Color.clear)
                    .frame(width: inner, height: inner)
                ForEach(headings, id: \.self) { input in
                    Path { path in
                        let heading = Double(input)-90.0
                        let runway = Angle.degrees(heading)
                        let runwayCos : CGFloat =  CGFloat(cos(runway.radians))
                        let runwaySin : CGFloat =  CGFloat(sin(runway.radians))
                        let from = CGPoint(x: center.x + runwayCos * (inner-circleStroke) * 0.5,
                                           y: center.y + runwaySin * (inner-circleStroke) * 0.5)
                        let to = CGPoint(x: center.x + runwayCos * outer * 0.5,
                                         y: center.y + runwaySin * outer * 0.5)
                        
                        path.move(to: from)
                        path.addLine(to: to)
                    }
                    .stroke(lineWidth: runwayStroke)
                    .foregroundColor(Color.blue)
                }
                
            }
                
        }
    }
}


struct AirportIcon_Previews: PreviewProvider {
    static func samples() -> [Airport] {
        let db = FMDatabase(url: Bundle.main.url(forResource: "airports", withExtension: "db"))
        db.open()
        var rv : [Airport] = []
        for ident in ["EGTF","LFMD"]{
           let airport = try? Airport(db: db, ident: ident)
            if let airport = airport {
                rv.append(airport)
            }
        }
        return rv
    }
    static var previews: some View {
        let samples = AirportIcon_Previews.samples()
        VStack {
            ForEach(samples) { airport in
                AirportIcon(airport: airport)
               .frame(width: 150.0,height: 150.0)
                    .padding()
            }
        }
    }
}
