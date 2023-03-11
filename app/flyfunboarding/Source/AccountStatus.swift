//
//  AccountStatus.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
//

import Foundation
import AuthenticationServices
import OSLog

class AccountStatus : ObservableObject {
    
    @Published var signedIn : Bool = false
    
    init() {
        self.validateCredential()
    }
    
    func validateCredential() {
        let appleProvider = ASAuthorizationAppleIDProvider()
        if let user = Settings.shared.userIdentifier {
            appleProvider.getCredentialState(forUserID: user) {
                credentialState, error in
                var newStatus = false
                switch credentialState {
                case .authorized:
                    Logger.app.info("User logged in")
                    newStatus = true
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
