//  MIT License
//
//  Created on 21/03/2023 for flyfunboarding
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
import CodeScanner
import OSLog

struct ScanTicketView: View {
    enum Status {
        case scanning
        case checking
        case valid
        case invalid
    }
    @State private var scannedString : String? = nil
    @State  var status : Status = .scanning
    @State var ticket : Ticket = Ticket.defaultTicket
    @State var validColor : Color = Color.green
    @State var validText : String = "Valid Ticket"

    func verify(string : String) {
        scannedString = string
        if
           let data = string.data(using: .utf8) {
            Logger.ui.info("Scanned \(string)")
            if let signature = try? JSONDecoder().decode(Ticket.Signature.self, from: data) {
                RemoteService.shared.verifyTicket(signature: signature) {
                    ticket in
                    if let ticket = ticket {
                        DispatchQueue.main.async {
                            self.status = .valid
                            self.ticket = ticket
                            if self.ticket.validToday {
                                self.validColor = Color.green
                                self.validText = "Welcome on Board"
                            }else{
                                self.validColor = Color.purple
                                self.validText = "Not for today"
                            }
                        }
                    }else{
                        self.status = .invalid
                    }
                }
                self.status = .checking
            }else{
                self.status = .invalid
            }
        }else{
            self.status = .invalid
        }
    }
    var body: some View {
        GeometryReader { geometry in
            VStack {
                CodeScannerView(codeTypes: [.qr], scanMode: .continuous, showViewfinder: true, simulatedData: "0"){
                    response in
                    if case let .success(result) = response {
                        self.verify(string: result.string)
                    }
                }
                    .padding()
                    .frame(width: min(450.0,geometry.size.width), height: geometry.size.height / 2.0)
                
                switch self.status {
                case .checking:
                    VStack {
                        Text("Checking validity")
                        ProgressView()
                    }
                case .scanning:
                    Text("Scan a ticket")
                case .invalid:
                    VStack {
                        Image(systemName: "xmark.seal.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.red)
                            .frame(width: min(100.0,geometry.size.width / 4.0),
                                   height: min(100.0,geometry.size.width/4.0))
                        Text("Invalid Ticket")
                            .font(.largeTitle)
                    }
                case .valid:
                    VStack {
                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(self.validColor)
                            .frame(width: min(100.0,geometry.size.width / 4.0),
                                   height: min(100.0,geometry.size.width/4.0))
                        Text("Valid Ticket")
                            .font(.title)
                            
                        Text(self.validText)
                            .fontWeight(.bold)
                            .padding(.bottom)
                        HStack {
                            Spacer()
                            TicketRowView(ticket: self.ticket)
                                .frame(maxWidth: 500.0)
                                .padding()
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth:.infinity,alignment: .center)
        }
    }
}

struct ScanTicketView_Previews: PreviewProvider {
    static var previews: some View {
        let tickets = Samples.tickets
        Group {
            ScanTicketView()
                .previewDisplayName("Scanning")
            ScanTicketView(status: .invalid)
                .previewDisplayName("invalid")
            ScanTicketView(status: .valid, ticket: tickets[0], validColor: .purple, validText: "Not for today")
                .previewDisplayName("Valid Different day")
            ScanTicketView(status: .valid, ticket: tickets[0], validColor: .green, validText: "Welcome on Board")
                .previewDisplayName("Valid today")
        }
    }
}
