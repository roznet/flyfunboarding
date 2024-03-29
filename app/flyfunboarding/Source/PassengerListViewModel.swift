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
import SwiftUI
import Contacts

class PassengerListViewModel : ObservableObject {
    @Published var passengers : [Passenger] = []
    var syncWithRemote : Bool = true
    
    init(passengers : [Passenger], syncWithRemote: Bool = true) {
        self.passengers = passengers
        self.syncWithRemote = syncWithRemote
    }

    func retrievePassengers() {
        if self.syncWithRemote {
            RemoteService.shared.retrievePassengerList() {
                passengers in
                DispatchQueue.main.async {
                    self.passengers = passengers?.sorted(by: { $0.moreRecent(than: $1) }) ?? []
                }
            }
        }
    }
    
    func add(passenger: Passenger, completion: @escaping (Passenger?) -> Void) {
        RemoteService.shared.registerPassenger(passenger: passenger) {
            _ in
            // Does not matter if failed or not, just retrieve
            self.retrievePassengers()
        }
    }
    
    
}
