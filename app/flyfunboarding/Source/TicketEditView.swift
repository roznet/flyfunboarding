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
extension Notification.Name {
    static let ticketModified = Notification.Name("ticketModified")
}
struct TicketEditView: View {
    typealias Mode = StandardEditButtons.Mode

    @StateObject var ticketModel : TicketViewModel
    @Environment(\.dismiss) var dismiss
    
    var ticket : Ticket { return self.ticketModel.ticket }
    
    init(ticket : Ticket, mode : Mode) {
        _ticketModel = StateObject(wrappedValue: TicketViewModel(ticket: ticket, mode: mode))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            PassengerRowView(passenger: ticketModel.passenger, highlightName: true)
            .padding([.bottom,.leading,.trailing])
            
            HStack(alignment: .firstTextBaseline) {
                Text("Seat Number").standardFieldLabel()
                TextField("Seat Number", text: $ticketModel.seatNumber).standardStyle()
            }
            .padding(.horizontal)
            StandardEditButtons(mode: ticketModel.mode,
                                submit: ticketModel.submitText,
                                delete: "Delete", submitAction: issue, deleteAction: delete)
            Divider()
            FlightEditView(flight: ticketModel.flight,
                           mode: .edit
            ).disabled(true)
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
                    NotificationCenter.default.post(name: .ticketModified, object: nil)
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
                NotificationCenter.default.post(name: .ticketModified, object: nil)
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }
        }
    }

}

struct TicketEditView_Previews: PreviewProvider {
    static var previews: some View {
        let tickets = Samples.tickets
        TicketEditView(ticket: tickets.first!, mode: .create)
    }
}
