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
import SwiftUI
import CoreLocation
import RZFlight
import OSLog

struct AirportField: View {
    typealias AirportCoord = KnownAirports.AirportCoord
    
    @State var labelText : String
    @State var icao : String
    @State var name : String = ""
    var onSelectAction : ((AirportCoord) -> Void)?
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(self.labelText)
                .standardFieldLabel()
            NavigationLink(destination: AirportPicker(icao: $icao, search: icao).onSelect() {
                ac in
                onSelectAction?(ac)
            }){
                VStack {
                    TextField("ICAO", text: $icao)
                        .standardStyle()
                    Text(name)
                        .standardInfo()
                }
            }
        }
        .onAppear(){
            self.sync()
        }
    }
    
    func sync(){
        FlyFunBoardingApp.worker.async {
            if let airport = Airport.find(icao: self.icao) {
                DispatchQueue.main.async {
                    self.name = airport.name
                }
            }
        }
    }
}


struct AirportPicker_Previews: PreviewProvider {
    static var previews: some View {
        AirportPicker(icao: .constant("EGTF"), search: "EGTF")
    }
}
