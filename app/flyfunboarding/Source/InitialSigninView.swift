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
import AuthenticationServices
import OSLog

struct InitialSigninView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var accountStatus : AccountModel
    
    @State private var airlineName : String = Settings.shared.airlineName
    @State private var isTextFieldEmpty : Bool =  Settings.shared.airlineName.isEmpty
    
    var body: some View {
        VStack {
            VStack {
                Image("FlyFunLogo")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text(NSLocalizedString("Welcome to FlyFun Boarding", comment: ""))
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding()
                Text(NSLocalizedString("To create your Airline, and start issuing boarding pass, give it a name and Sign In With Apple", comment: "")).multilineTextAlignment(.center)
            }
            Spacer()
            VStack{
                HStack{
                    Text( NSLocalizedString("Airline Name", comment: ""))
                    TextField(NSLocalizedString("My Airline", comment: ""), text: $airlineName)
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
                    Text(NSLocalizedString("Enter a name to enable sign in", comment: ""))
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

    func register(authorization : ASAuthorization) {
        if let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleCredential.user
            let fullName = appleCredential.fullName
            
            Settings.shared.userIdentifier = userIdentifier
            Settings.shared.userFullName = fullName
            let airline = Airline(airlineName: self.airlineName,
                                  appleIdentifier: userIdentifier,
                                  airlineId: nil,
                                  airlineIdentifier: nil
            )
            RemoteService.shared.registerAirline(airline: airline){
                remoteAirline in
                if let remoteAirline = remoteAirline {
                    Settings.shared.currentAirline = remoteAirline
                    DispatchQueue.main.async {
                        self.accountStatus.signedIn = true
                    }
                }else{
                    Logger.net.error("Failed to register airline?")
                    self.accountStatus.signedIn = false
                }
            }
           
        }
    }
    
    func signInButton(_ style: SignInWithAppleButton.Style) -> some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName]
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    // Handle autorization
                    self.register(authorization: authorization)
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
