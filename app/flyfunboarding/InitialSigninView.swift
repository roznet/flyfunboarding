//
//  InitialSigninView.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
//

import SwiftUI
import AuthenticationServices
import OSLog

struct InitialSigninView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var accountStatus : AccountStatus
    
    @State private var airlineName : String = Settings.shared.airlineName
    @State private var isTextFieldEmpty : Bool =  Settings.shared.airlineName.isEmpty
    
    var body: some View {
        VStack {
            VStack {
                Image("FlyFunLogo")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Welcome to FlyFun Boarding")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding()
                Text("To create your Airline, and start issuing boarding pass, give it a name and Sign In With Apple").multilineTextAlignment(.center)
            }
            Spacer()
            VStack{
                HStack{
                    Text( "Airline Name")
                    TextField("My Airline", text: $airlineName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: airlineName) {
                            value in
                            isTextFieldEmpty = value.isEmpty
                        }
                }
            }
            Spacer()
            VStack {
                if isTextFieldEmpty {
                    Text("Enter a name to enable sign in")
                        .foregroundColor(.secondary)
                }else{
                    if colorScheme.self == .dark {
                        signInButton(.whiteOutline)
                            .disabled(isTextFieldEmpty)
                    } else {
                        signInButton(.black)
                            .disabled(isTextFieldEmpty)
                    }
                }
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
                    Logger.app.info("authorization \(authorization)")
                    if let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        let userIdentifier = appleCredential.user
                        let fullName = appleCredential.fullName
                        
                        //let token = appleCredential.identityToken
                        
                        Settings.shared.userIdentifier = userIdentifier
                        Settings.shared.userFullName = fullName
                        let airline = Airline(airlineName: self.airlineName, appleIdentifier: userIdentifier, airlineId: nil)
                        RemoteService.shared.registerAirline(airline: airline){
                            remoteAirline in
                            if let aId = remoteAirline?.airlineId, aId > 0 {
                                Settings.shared.airlineId = aId
                                self.accountStatus.signedIn = true
                            }
                        }
                    }
                    break
                case .failure(let error):
                    // Handle error
                    Logger.app.error("failed to authorize \(error)")
                    break
                }
            }
        )
        .frame(width: 200, height: 40, alignment: .center)
        .signInWithAppleButtonStyle(style)
    }
    
    
}

struct InitialSigninView_Previews: PreviewProvider {
    static var previews: some View {
        InitialSigninView()
    }
}
