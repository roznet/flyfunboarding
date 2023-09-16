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
import RZUtilsSwiftUI
import OSLog

struct AccountAndSettingsView: View {
    @EnvironmentObject var accountStatus : AccountModel
    @Environment(\.dismiss) var dismiss
    @State private var isPresentingConfirm : Bool = false
    @StateObject var airlineViewModel = AirlineViewModel(airline: Settings.shared.currentAirline ?? Airline())
    var body : some View {
        VStack {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }.padding([.top,.trailing])
            }
            ScrollView {
                VStack {
                    Image("FlyFunLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.accentColor)
                    Text(NSLocalizedString("Welcome to FlyFun Boarding", comment: ""))
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    VStack {
                        Text("Edit your airline's Name")
                        ToggledTextField(text: $airlineViewModel.airlineName, image: nil, action: update)
                    }.padding()
                    HStack {
                        Toggle(isOn: $airlineViewModel.customLabelEnabled){
                            HStack {
                                Text("Custom Label")
                                TextField("Custom Label", text: $airlineViewModel.customLabel)
                                    .standardStyle()
                                    .onChange(of: airlineViewModel.customLabel) {
                                        _ in
                                        self.airlineViewModel.settingsChanged()
                                    }
                            
                            }
                            .foregroundColor(self.airlineViewModel.customLabelEnabled ? .primary : .secondary)
                            .disabled(!self.airlineViewModel.customLabelEnabled)
                        }
                        .onChange(of: airlineViewModel.customLabelEnabled){
                            _ in
                            self.airlineViewModel.settingsChanged()
                        }
                            
                    }.padding([.trailing,.leading])
                    VStack {
                        ColorPicker("Boarding Pass Color", selection: $airlineViewModel.bgColor)
                            .onChange(of: airlineViewModel.bgColor) {
                                _ in
                                self.airlineViewModel.settingsChanged()
                            }
                        ColorPicker("Label Color", selection: $airlineViewModel.labelColor)
                            .onChange(of: airlineViewModel.labelColor) {
                                _ in
                                self.airlineViewModel.settingsChanged()
                            }
                        ColorPicker("Text Color", selection: $airlineViewModel.textColor)
                            .onChange(of: airlineViewModel.textColor) {
                                _ in
                                self.airlineViewModel.settingsChanged()
                            }
                    }.padding()
                }
                Spacer()
                VStack {
                    Text(NSLocalizedString("You can sign out or delete your airline and all its data. Deleting your data can't be undone.", comment: "")).multilineTextAlignment(.center)
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
                HStack {
                    VStack {
                        Text("Label").foregroundColor(self.airlineViewModel.labelColor)
                        Text("Name").foregroundColor(self.airlineViewModel.textColor)
                    }
                }
                .padding()
                .background(self.airlineViewModel.bgColor)
                .cornerRadius(15)
                Spacer()
            }
        }
    }
    
    func signOut() {
        Settings.shared.currentAirline = nil
    }
    func update() {
        Logger.ui.info("Update name")
        self.airlineViewModel.updateAirline()
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
