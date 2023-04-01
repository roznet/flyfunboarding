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
import UIKit


struct Passenger : Codable, Identifiable, Hashable, Equatable {
    static func == (lhs: Passenger, rhs: Passenger) -> Bool {
        return lhs.apple_identifier == rhs.apple_identifier
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.apple_identifier)
    }
    
    var formattedName : String
    var passenger_id : Int?
    var apple_identifier : String
    var passenger_identifier : String?
    var stats : [Stats]?
    
    static var defaultPassenger = Passenger(name: "")
    
    var id = UUID()
    
    enum CodingKeys: String, CodingKey {
        case formattedName, passenger_id, apple_identifier,passenger_identifier,stats
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
        let keys : [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactImageDataAvailableKey as CNKeyDescriptor
        ]
        let contact = try? store.unifiedContact(withIdentifier: self.apple_identifier, keysToFetch: keys as [CNKeyDescriptor])
        return contact
    }
    
    func retrieveImage() -> UIImage? {
        let store = CNContactStore()
        let keys : [CNKeyDescriptor] = [
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]
        let contact = try? store.unifiedContact(withIdentifier: self.apple_identifier, keysToFetch: keys as [CNKeyDescriptor])
        if let available = contact?.imageDataAvailable, available, let data = contact?.thumbnailImageData {
            return UIImage(data: data)
        }else{
            return nil
        }
    }
  
    func moreRecent(than : Passenger) -> Bool {
        if let a = self.stats?.first, let b = than.stats?.first {
            return a.moreRecent(than: b)
        }
        return self.stats?.first != nil
    }
}
