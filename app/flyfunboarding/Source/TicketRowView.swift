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

struct TicketRowView: View {
    var ticket : Ticket
    var body: some View {
        VStack(alignment: .leading) {
                   
            ZStack {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(Color(UIColor.secondarySystemBackground))
                VStack {
                    HStack {
                        PassengerRowView(passenger: ticket.passenger, highlightName: true)
                        Spacer()
                    }
                    FlightRowView(flight: ticket.flight)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct TicketRowView_Previews: PreviewProvider {
    static var previews: some View {
        let tickets = Samples.tickets
        List {
            TicketRowView(ticket: tickets[0])
            TicketRowView(ticket: tickets[1])
        }
        
    }
}
