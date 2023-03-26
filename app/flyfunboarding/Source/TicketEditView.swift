//  MIT License
//
//  Created on 16/03/2023 for flyfunboarding
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

struct TicketEditView: View {

    @StateObject var ticketModel : TicketViewModel
    @ObservedObject var ticketListModel : TicketListViewModel
    @Environment(\.dismiss) var dismiss
    
    var ticket : Ticket { return self.ticketModel.ticket }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("Seat Number").standardFieldLabel()
                TextField("Seat Number", text: $ticketModel.seatNumber).standardStyle()
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text("Passenger")
                    .standardFieldLabel()
                Text(ticketModel.passenger.formattedName)
                    .standardFieldValue()
            }
            .padding(.bottom)
            FlightEditView(flightModel: FlightViewModel(flight: ticketModel.flight, mode: .edit),
                           editIsDisabled: true)
            StandardEditButtons(mode: ticketModel.mode,
                                submit: "Issue", delete: "Delete", submitAction: issue, deleteAction: delete)
            Spacer()
            if self.ticketModel.mode == .edit {
                self.boardingPassButtons()
            }
        }
    }
    
    func boardingPassButtons() -> some View{
       return
            HStack(alignment: .center) {
                Spacer()
                Button(action: boardingPassLink) {
                    Text("Download Pass")
                }.standardButton()
                Button(action: boardingPassFile) {
                    Text("Pass in Safari")
                }.standardButton().padding(.leading)
                Spacer()
            }
            .padding(.top)
    }
    
    
    func boardingPassFile() {
        if let url = ticket.disclaimerUrl {
            UIApplication.shared.open(url)
        }
    }
    func boardingPassLink() {
        if let url = ticket.downloadPassUrl {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return
            }
            
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            window.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func issue() {
        let ticket = self.ticketModel.ticket
        RemoteService.shared.issueTicket(ticket: ticket) {
            ticket in
            if let t = ticket {
                Logger.ui.info( "issued \(t)")
                DispatchQueue.main.async {
                    self.ticketModel.ticket = t
                    self.ticketModel.mode = .edit
                    self.ticketListModel.retrieveTickets()
                }
            }else{
                Logger.ui.error("Failed to issue ticket")
            }
        }
    }
    func delete() {
        Logger.ui.info( "Delete Ticket")
        RemoteService.shared.deleteTicket(ticket: self.ticket){
            result in
            if result {
                DispatchQueue.main.async {
                    self.ticketListModel.retrieveTickets()
                    self.dismiss()
                }
            }
        }
    }

}

struct TicketEditView_Previews: PreviewProvider {
    static var previews: some View {
        let tickets = Samples.tickets
        TicketEditView(ticketModel: TicketViewModel(ticket: tickets[0], mode: .edit), ticketListModel: TicketListViewModel.empty)
    }
}
