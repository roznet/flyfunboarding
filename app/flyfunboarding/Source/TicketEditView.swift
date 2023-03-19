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

struct TicketEditView: View {
    var ticket : Ticket
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("Passenger")
                    .standardFieldLabel()
                Text(ticket.passenger.formattedName)
                    .standardFieldValue()
                    .padding(.bottom)
            }
            FlightEditView(flightModel: FlightViewModel(flight: ticket.flight), editIsDisabled: true)
            HStack(alignment: .center) {
                Spacer()
                Button(action: downloadFile) {
                    Text("Share")
                }
                Button(action: issueTicket) {
                    Text("Open in Safari")
                }.padding(.leading)
                Spacer()
            }
        }
    }
    
    func issueTicket() {
        if let url = ticket.disclaimerUrl {
            UIApplication.shared.open(url)
        }
    }
    func downloadFile() {
        if let url = ticket.downloadPassUrl {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return
            }
            
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            window.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }

}

struct TicketEditView_Previews: PreviewProvider {
    static var previews: some View {
        let tickets = Samples.tickets
        TicketEditView(ticket: tickets[0])
    }
}
