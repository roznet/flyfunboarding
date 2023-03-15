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



struct AirlineView: View {
    @EnvironmentObject var accountModel : AccountModel
    @StateObject var airlineViewModel = AirlineViewModel()
    @State private var selectedTab = "Aircraft"
    
    var body: some View {
        VStack {
            HStack {
                ToggledTextField(text: $airlineViewModel.airlineName, image: Image("FlyFunLogo"))
                settingsButton
                    .padding(.trailing)
            }
            TabView(selection: $selectedTab) {
                PassengerListView()
                    .tabItem {
                        Image(systemName: "person")
                        Text(NSLocalizedString("Passengers", comment: "tabItem"))
                    }
                AircraftListView()
                    .tabItem {
                        Image(systemName: "airplane")
                        Text(NSLocalizedString("Airplanes", comment: "tabItem"))
                    }
                FlightListView()
                    .tabItem {
                        Image(systemName: "network")
                        Text(NSLocalizedString("Flights", comment: "tabItem"))
                    }
                TicketListView()
                    .tabItem {
                        Image(systemName: "wallet.pass")
                        Text(NSLocalizedString("Tickets", comment: "tabItem"))
                    }
            }
        }
    }
                             
    @State var settingsPresented = false
    var settingsButton : some View {
        return Button(action: {
            settingsPresented.toggle()
        }) {
            Image(systemName: "gearshape")
        }
        .sheet(isPresented: $settingsPresented){
            AirlineSettingsView()
        }
    }
  
    func signOut() {
        self.accountModel.signedIn = false
    }
}

struct AirlineView_Previews: PreviewProvider {
    static var previews: some View {
        AirlineView(airlineViewModel: createAirlineViewModel())
            .environmentObject(createAccountModel())
    }

    static func createAccountModel() -> AccountModel {
        let rv = AccountModel()
        rv.signedIn = true
        return rv
    }
    
    static func createAirlineViewModel() -> AirlineViewModel {
        if let airline = Samples.airline {
            let viewModel = AirlineViewModel(airline: airline)
            return viewModel
        }else{
            return AirlineViewModel()
        }
    }
}
