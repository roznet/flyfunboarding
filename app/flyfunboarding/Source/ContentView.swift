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
    @Environment(\.colorScheme) var colorScheme
    
    @State private var username : String = ""
    @State private var password : String = ""
    
    var body: some View {
        VStack {
            VStack {
                Image("FlyFunLogo")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Welcome to FlyFun Boarding")
                    .font(.title)
                Text("To create your Airline please Sign In")
            }
            Spacer()
            VStack {
                HStack {
                    Text( "User Name")
                    TextField("User Name", text: $username)
                }
                HStack {
                    Text( "Password")
                    TextField("Password", text: $password)
                }
                HStack {
                    Spacer()
                    Button("Load") {
                        self.username = Settings.shared.airlineName
                        self.password = Settings.shared.userIdentifier ?? ""
                    }
                    Spacer()
                    Button("Save") {
                        Settings.shared.airlineName = self.username
                        if self.password == "" {
                            Settings.shared.userIdentifier = nil
                        }else{
                            Settings.shared.userIdentifier = self.password
                        }
                    }
                    Spacer()
                }
            }
            if colorScheme.self == .dark {
                signInButton(.whiteOutline)
            } else {
                signInButton(.black)
            }
            Spacer()
            
        }
        .padding()
    }

    func signInButton(_ style: SignInWithAppleButton.Style) -> some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName ]
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    // Handle autorization
                    Logger.app.info("authorizatoin \(authorization)")
                    break
                case .failure(let error):
                    // Handle error
                    Logger.app.error("failed to authorize \(error)")
                    break
                }
            }
        )
        .frame(width: 280, height: 60, alignment: .center)
        .signInWithAppleButtonStyle(style)
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
