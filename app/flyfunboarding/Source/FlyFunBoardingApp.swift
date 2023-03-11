//
//  flyfunboardingApp.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 10/03/2023.
//

import SwiftUI
import OSLog
import RZUtilsSwift
import AuthenticationServices

@main
struct FlyFunBoardingApp: App {
    init() {
        Secrets.shared = Secrets(url: Bundle.main.url(forResource: "secrets", withExtension: "json"))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
