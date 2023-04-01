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



import SwiftUI
import Contacts

struct PassengerEditView: View {
    @Environment(\.isEnabled) private var isEnabled
    @StateObject var passengerModel : PassengerViewModel
    @StateObject var ticketListViewModel : TicketListViewModel
    
    init(passenger : Passenger,
         tickets: [Ticket] = [],
         syncWithRemote : Bool = true) {
        _passengerModel = StateObject(wrappedValue: PassengerViewModel(passenger: passenger))
        _ticketListViewModel = StateObject(wrappedValue: TicketListViewModel(tickets: tickets, passenger: passenger, syncWithRemote: syncWithRemote))
    }
    
    var body: some View {
        VStack {
            VStack {
                Text( "Contact" ).standardFieldLabel()
                
                HStack {
                    if let thumbnail = self.passengerModel.thumbnail  {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .frame(maxWidth: 50.0, maxHeight: 50.0)
                    }
                    Text(self.passengerModel.contactFormattedName).standardFieldValue()
                    Spacer()
                }
            }.padding()
            Divider()
            
            HStack {
                Text("Display as").standardFieldLabel()
                TextField("name", text: $passengerModel.displayName).standardStyle()
            }
            .padding(.horizontal)
            
            if self.ticketListViewModel.tickets.count > 0 {
                List() {
                    Section("Tickets") {
                        ForEach(self.ticketListViewModel.tickets) { ticket in
                            NavigationLink(value: ticket){
                                TicketRowView(ticket: ticket)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .onAppear() {
            self.ticketListViewModel.retrieveTickets()
        }
    }
}

struct PassengerEditView_Previews: PreviewProvider {
    static var previews: some View {
        let passenger = Samples.passengers.first!
        let tickets = Samples.tickets
        PassengerEditView(passenger: passenger, tickets: tickets, syncWithRemote: false)
    }
}
