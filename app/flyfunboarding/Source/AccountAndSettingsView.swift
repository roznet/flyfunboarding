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

struct AccountAndSettingsView: View {
    @EnvironmentObject var accountStatus : AccountModel
    @Environment(\.dismiss) var dismiss
    @State private var isPresentingConfirm : Bool = false

    
    var body : some View {
        VStack {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }.padding(.trailing)
            }
            VStack {
                Image("FlyFunLogo")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text(NSLocalizedString("Welcome to FlyFun Boarding", comment: ""))
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding()
                Text(NSLocalizedString("You can sign out or delete your airline and all its data, which can't be undone", comment: "")).multilineTextAlignment(.center)
            }
            Spacer()
            HStack {
                Spacer()
                Button("Delete Airline", role: .destructive) {
                    self.isPresentingConfirm = true
                }
                    .standardButton()
                    .padding(.trailing)
                    .confirmationDialog("Are you sure?", isPresented: $isPresentingConfirm){
                        Button("Delete all your Data", role: .destructive) {
                            deleteAction()
                        }
                    } message: {
                        Text( "Are you sure? This can't be undone")
                    }
                Button("Signout", action: signOut).standardButton()
                Spacer()
            }
            Spacer()
        }
    }
    
    func signOut() {
        Settings.shared.currentAirline = nil
    }
    
    func deleteAction() {
        RemoteService.shared.deleteCurrentAirline() {
            success in
            if success {
                Settings.shared.currentAirline = nil
            }
        }
    }
}

struct AirlineSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountAndSettingsView()
    }
}
