//
//  AirlineView.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
//

import SwiftUI
import OSLog

struct AirlineView: View {
    @EnvironmentObject var accountStatus : AccountStatus
    @StateObject var airlineViewModel = AirlineViewModel()
    @State private var isEditingAirlineName : Bool = false
    
    var body: some View {
        HStack {
            Image("FlyFunLogo")
                .resizable()
                .frame(width: 50.0, height: 50.0)
                .foregroundColor(.accentColor)
            if self.isEditingAirlineName {
                TextField("Airline Name", text: $airlineViewModel.airlineName)
                    .textFieldStyle(.roundedBorder)
            }else{
                TextField("Airline Name", text: $airlineViewModel.airlineName)
                    .textFieldStyle(.plain)
                    .disabled(true)
            }
            Button(action: {
                if self.isEditingAirlineName {
                    Logger.ui.info("Save airline name")
                    self.airlineViewModel.updateAirline()
                }
                self.isEditingAirlineName = !self.isEditingAirlineName
            }) {
                if self.isEditingAirlineName {
                    Image(systemName: "square.and.arrow.down")
                        .renderingMode(.template)
                }else{
                    Image(systemName: "square.and.pencil")
                        .renderingMode(.template)
                }
            }
        }
        Spacer()
        HStack {
            Button("Re-register") {
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
            Button("Sign Out") {
                self.accountStatus.signedIn = false
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
