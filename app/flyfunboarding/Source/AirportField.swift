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
extension Notification.Name {
    static let airportSourceChanged = Notification.Name("airportSourceChange")

}
struct AirportField: View {
    
    // Ideally, we would use icao binding or a call back
    // but somehow it freezes, so that's why we are using choice and a notification for the change.
    @State var labelText : String
    @Binding var icao : String
    @State var name : String = ""
    @State var choice : String = ""
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(self.labelText)
                .standardFieldLabel()
            NavigationLink(destination: AirportPicker(icao: $choice, search: icao)){
                VStack {
                    TextField("ICAO", text: $choice)
                        .standardStyle()
                        .disabled(true)
                    Text(name)
                        .standardInfo()
                }
            }
        }
        .onAppear(){
            self.sync()
            NotificationCenter.default.addObserver(forName: .airportWasPicked, object: nil, queue: nil){ _ in
                DispatchQueue.main.async {
                    self.icao = self.choice
                }
            }
            NotificationCenter.default.addObserver(forName: .airportSourceChanged, object: nil, queue: nil){
                _ in
                DispatchQueue.main.async {
                    self.choice = self.icao
                    self.sync()
                }
            }
        }
        .onDisappear(){
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    func sync(){
        FlyFunBoardingApp.worker.async {
            if let airport = Airport.find(icao: self.icao) {
                DispatchQueue.main.async {
                    self.name = airport.name
                    self.choice = self.icao
                    Settings.shared.notice(lastAirportIdent: self.icao)
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
