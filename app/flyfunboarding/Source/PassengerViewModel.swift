//  MIT License
//
//  Created on 01/04/2023 for flyfunboarding
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
import Contacts
import UIKit

class PassengerViewModel : ObservableObject {
    private var passenger : Passenger
    @Published var displayName : String
    @Published var contactFormattedName : String = ""
    @Published var thumbnail : UIImage? = nil
    
    init(passenger : Passenger){
        self.passenger = passenger
        self.displayName = passenger.formattedName
        self.sync()
    }
    
    func sync() {
        if let contact = self.passenger.retrieveContact() {
            let formatter = CNContactFormatter()
            formatter.style = .fullName
            self.contactFormattedName = formatter.string(from: contact) ?? "No name"
            self.thumbnail = self.passenger.retrieveImage()
        }
    }
}
