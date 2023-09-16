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
import RZUtilsSwiftUI
import OSLog


struct MainView: View {
    var airport : Airport? = nil
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        switch horizontalSizeClass {
        case .regular:
            zStack
        case .compact,.none:
            zStack
        case .some(_):
            vStack
        }
    }
    
    var zStack : some View {
        NavigationSplitView {
            VStack {
                SearchView()
                //Spacer()
                AirportView(airport: airport)
                Spacer()
            }
        } detail: {
            MapView()
                .frame(maxWidth: .infinity)
                .toolbar() {
                    ToolbarItemGroup {
                        Button {
                            Logger.app.info("HIDE")
                        } label: {
                            Image(systemName: "eye.slash")
                        }
                        Button {
                            Logger.app.info("CUSTOM")
                        } label: {
                            Image(systemName: "person.badge.shield.checkmark")
                        }
                    }
                }
        }
    }
    
    var hStack : some View {
        HStack {
            AirportView(airport: airport)
                .frame(maxWidth: .infinity)
                .padding()
            MapView()
                .frame(maxWidth: .infinity)
        }
    }
    var vStack : some View {
        VStack {
            AirportView(airport: airport)
                .frame(maxWidth: .infinity)
                .padding()
            MapView()
                .frame(maxWidth: .infinity)
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
