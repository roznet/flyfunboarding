//
//  ContentView.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 10/03/2023.
//

import SwiftUI
import AuthenticationServices
import OSLog


struct ContentView: View {
    @StateObject private var accountStatus : AccountStatus = AccountStatus()
    
    var body: some View {
        if accountStatus.signedIn {
            AirlineView().environmentObject(accountStatus)
        }else{
            InitialSigninView().environmentObject(accountStatus)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
}
