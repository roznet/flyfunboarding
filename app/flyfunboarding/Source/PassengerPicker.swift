//  MIT License
//
//  Created on 23/03/2023 for flyfunboarding
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

class MatchedPassenger : ObservableObject {
    private var passengers : [Passenger] = []
    @Published var suggestions : [Passenger] = []

    init(passengers : [Passenger]? = nil) {
        if let passengers = passengers {
            self.passengers = passengers
            self.suggestions = passengers
        }else{
            self.passengers = []
            self.suggestions = []
        }
    }

    func retrievePassengers() {
        RemoteService.shared.retrievePassengerList() { found in
            if let passengers = found {
                DispatchQueue.main.async {
                    self.passengers = passengers
                    self.suggestions = passengers
                }
            }
        }
    }
}

struct PassengerPicker: View {
    @StateObject var matchedPassenger = MatchedPassenger()
    @Binding var passenger : Passenger
    
    var completion : () -> Void = {}
    
    var body: some View {
        List(matchedPassenger.suggestions) { passenger in
            Text(passenger.formattedName)
                .onTapGesture {
                    self.passenger = passenger
                    completion()
                }
        }
        .standardNavigationBarTitle("Choose Passenger")
        .onAppear() {
            self.matchedPassenger.retrievePassengers()
        }
    }
}

