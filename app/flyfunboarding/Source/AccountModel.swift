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
import AuthenticationServices
import OSLog

class AccountModel : ObservableObject {
   
    enum Status {
        case unknown
        case signedIn
        case notSignedIn
    }
    @Published var signedIn : Status = .unknown
    
    init() {
        self.validateCredential()
        NotificationCenter.default.addObserver(forName: .signinStatusChanged, object: nil, queue: nil){
            _ in
            DispatchQueue.main.async {
                self.signedIn = (Settings.shared.currentAirline != nil) ? .signedIn : .notSignedIn
            }
        }
    }
    
    func validateCredential() {
        let appleProvider = ASAuthorizationAppleIDProvider()
        if let user = Settings.shared.userIdentifier {
            appleProvider.getCredentialState(forUserID: user) {
                credentialState, error in
                var newStatus : Status = .notSignedIn
                switch credentialState {
                case .authorized:
                    Logger.app.info("User logged in \(user)")
                    newStatus = .signedIn
                    if Settings.shared.airlineIdentifier == nil {
                        Logger.app.error("Logged in but airlineIdentifier missing")
                        newStatus = .notSignedIn
                    }
                        
                case .revoked, .notFound, .transferred:
                    Logger.app.info("User not logged in")
                default:
                    break
                }
                DispatchQueue.main.async {
                    self.signedIn = newStatus
                }
            }
        }
        
    }
}
