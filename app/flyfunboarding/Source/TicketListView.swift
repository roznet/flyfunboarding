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
import OSLog

struct TicketListView: View {
    enum Stage {
        case edit
        case passenger
        case flight
    }
    
    @State private var navPath = NavigationPath()
    @StateObject var ticketListViewModel = TicketListViewModel(tickets: [])
    
    var body: some View {
        NavigationStack(path: $navPath) {
            List(ticketListViewModel.tickets) { ticket in
                NavigationLink(destination: self.ticketEditView(ticket: ticket) ){
                    TicketRowView(ticket: ticket)
                }
            }
            .navigationDestination(for: Int.self) {
                i in
                if i == 0 {
                    self.chooseFlight()
                }else if i == 1 {
                    self.choosePassenger()
                }else if i == 2 {
                    self.newTicket()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: issue) {
                        VStack {
                            Image(systemName: "plus.circle")
                            Text("New")
                        }
                    }
                }
            }
        }
        .padding(.top)
        .onAppear() {
            self.ticketListViewModel.retrieveTickets()
        }
    }
    
    func chooseFlight() -> some View {
        var rv = FlightPicker(flight: $ticketListViewModel.flight)
        rv.completion = {
            self.navPath.removeLast()
            self.navPath.append(1)
        }
        return rv
        
    }
    
    func choosePassenger() -> some View {
        var rv = PassengerPicker(passenger: $ticketListViewModel.passenger)
        rv.completion = {
            self.navPath.removeLast()
            self.navPath.append(2)
        }
        return rv
    }
    
    func newTicket() -> some View {
        let ticket = Ticket(passenger: self.ticketListViewModel.passenger, flight: self.ticketListViewModel.flight, seatNumber: "")
        return TicketEditView(ticketModel: TicketViewModel(ticket: ticket, mode: .create), ticketListModel: self.ticketListViewModel)
    }
    
    func ticketEditView(ticket: Ticket) -> some View {
        return TicketEditView(ticketModel: TicketViewModel(ticket: ticket, mode: .edit), ticketListModel: self.ticketListViewModel)
    }
    
    //MARK: - Actions

    func issue() {
        self.navPath.append(0)
    }
}

struct TicketListView_Previews: PreviewProvider {
    static var previews: some View {
        TicketListView()
    }
}
