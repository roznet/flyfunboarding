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

struct ToggledTextField: View {
    @Binding var text : String
    @Binding var isEditing : Bool

    var image : Image

    @ViewBuilder
    var textfield : some View {
        if self.isEditing {
            TextField("Airline Name", text: $text)
                .textFieldStyle(.roundedBorder)
        }else{
            TextField("Airline Name", text: $text)
                .textFieldStyle(.plain)
                .disabled(true)
        }
    }

    var icon : Image {
        if self.isEditing {
            return Image(systemName: "square.and.arrow.down")
                .renderingMode(.template)
        }else{
            return Image(systemName: "square.and.pencil")
                .renderingMode(.template)
        }
    }
    func toggle() {
        if self.isEditing {
            Logger.ui.info("Save airline name")
        }
        self.isEditing = !self.isEditing
    }
    
    @ViewBuilder
    var header : some View {
        HStack {
            image
                .resizable()
                .frame(width: 50.0, height: 50.0)
                .foregroundColor(.accentColor)
                .padding(.leading)
            textfield
            Button(action: toggle){
                icon
            }.padding(.trailing)
        }
    }
   
    var body: some View {
            header
    }
}
struct AirlineSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body : some View {
        Button("Done") {
            dismiss()
        }
        
    }
}
struct AirlineView: View {
    @EnvironmentObject var accountStatus : AccountStatus
    @StateObject var airlineViewModel = AirlineViewModel()
    @State private var isEditingAirlineName : Bool = false
    @State private var selectedTab = "Aircraft"
   
    var body: some View {
        VStack {
            HStack {
                ToggledTextField(text: $airlineViewModel.airlineName, isEditing: $isEditingAirlineName, image: Image("FlyFunLogo"))
                settingsButton
                    .padding(.trailing)
            }
            TabView(selection: $selectedTab) {
                AircraftListView()
                    .tabItem {
                        Image(systemName: "airplane")
                        Text("Airplanes")
                    }
                PassengerListView()
                    .tabItem {
                        Image(systemName: "person")
                        Text("Passengers")
                    }
                FlightListView()
                    .tabItem {
                        Image(systemName: "network")
                        Text("Flights")
                    }
                TicketListView()
                    .tabItem {
                        Image(systemName: "wallet.pass")
                        Text("Tickets")
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
        self.accountStatus.signedIn = false
        
    }
    func forceRegister() {
        if let identifier = Settings.shared.userIdentifier {
            let airline = Airline(airlineName: Settings.shared.airlineName,
                                  appleIdentifier: identifier,
                                  airlineId: nil)
            RemoteService.shared.registerAirline(airline: airline) {
                found in
                if let found = found {
                    DispatchQueue.main.async {
                        self.airlineViewModel.airline = found
                    }
                }
            }
        }
    }
}

struct AirlineView_Previews: PreviewProvider {
    static var previews: some View {
            
        AirlineView(airlineViewModel: createAirlineViewModel())
            .environmentObject(createAccountStatus())
    }

    static func createAccountStatus() -> AccountStatus {
        let rv = AccountStatus()
        rv.signedIn = true
        return rv
    }
    
    static func createAirlineViewModel() -> AirlineViewModel {
        if let url = Bundle.main.url(forResource: "sample_airline", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let airline = try? JSONDecoder().decode(Airline.self, from: data) {
            let viewModel = AirlineViewModel(airline: airline)
            return viewModel
        }else{
            return AirlineViewModel()
        }
    }
}
