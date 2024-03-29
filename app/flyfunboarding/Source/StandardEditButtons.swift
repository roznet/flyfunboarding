//  MIT License
//
//  Created on 22/03/2023 for flyfunboarding
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

struct StandardEditButtons: View {
    @State private var isPresentingConfirm : Bool = false
    
    enum Mode {
        case edit
        case create
    }
    
    private var deleteName : String
    private var submitString : String
    private var mode : Mode
    
    private var submitAction : () -> Void
    private var deleteAction : () -> Void
    
    init(mode: Mode, submit: String, delete: String, submitAction: @escaping () -> Void, deleteAction: @escaping () -> Void){
        self.mode = mode
        self.deleteName = delete
        self.submitString = submit
        self.submitAction = submitAction
        self.deleteAction = deleteAction
    }
    
    var body: some View {
        HStack {
            Spacer()
            if self.mode == .edit {
                Button(self.deleteName, role: .destructive) {
                    isPresentingConfirm = true
                }
                .standardButton()
                .confirmationDialog("Are you sure?", isPresented: $isPresentingConfirm){
                    Button(deleteName, role: .destructive) {
                        deleteAction()
                    }
                }
            }
            Button(action: submitAction) {
                Text(self.submitString)
            }.standardButton()
            Spacer()
        }
    }
}

struct StandardEditButtons_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StandardEditButtons(mode: .create, submit: "Create", delete: "Delete", submitAction: {}, deleteAction: {})
            StandardEditButtons(mode: .edit, submit: "Amend", delete: "Cancel", submitAction: {}, deleteAction: {})
        }
    }
}
