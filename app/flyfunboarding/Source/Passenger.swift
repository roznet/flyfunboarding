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
import Contacts


struct Passenger : Codable, Identifiable {
    
    var formattedName : String
    var passenger_id : Int?
    var apple_identifier : String
    var passenger_identifier : String?
    
    static var defaultPassenger = Passenger(name: "")
    
    var id : Int { return passenger_id ?? apple_identifier.hashValue }
    
    enum CodingKeys: String, CodingKey {
        case formattedName, passenger_id, apple_identifier,passenger_identifier
    }
    init(name: String) {
        self.formattedName = name
        self.apple_identifier = ""
        self.passenger_id = nil
        self.passenger_identifier = nil
    }
    init(contact : CNContact){
        self.apple_identifier = contact.identifier
        self.passenger_id = nil
        let comp = contact.identifier.split(separator: ":")
        if comp.count > 0 {
            self.passenger_identifier = String(comp.first!)
        }
       
        let formatter = CNContactFormatter()
        formatter.style = .fullName
        self.formattedName = formatter.string(from: contact) ?? "No Name"
    }

    mutating func syncWithContact() {
        if let contact = self.retrieveContact() {
            let formatter = CNContactFormatter()
            formatter.style = .fullName
            self.formattedName = formatter.string(from: contact) ?? "No Name"
        }
    }

    func retrieveContact() -> CNContact? {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactMiddleNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactThumbnailImageDataKey]
        let contact = try? store.unifiedContact(withIdentifier: self.apple_identifier, keysToFetch: keys as [CNKeyDescriptor])
        return contact
    }
   
}
