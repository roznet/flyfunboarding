//  MIT License
//
//  Created on 25/03/2023 for flyfunboarding
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


struct PassengerRowView: View {
    var passenger : Passenger
    var highlightName : Bool
    @State var passengerImage : Image = Image(systemName: "person")
    @State var hasImage : Bool = false
  
    func fetchImage() {
        let imageData = self.passenger.retrieveImageData()
        if let data = imageData,
           let uiImage = UIImage(data: data) {
            DispatchQueue.main.async {
                self.passengerImage = Image(uiImage: uiImage)
                self.hasImage = true
            }
        }else{
            self.passengerImage = Image(systemName: "person")
            self.hasImage = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if self.hasImage {
                    self.passengerImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }else{
                    Circle()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.secondarySystemBackground)
                }
                VStack {
                    if self.highlightName {
                        Text(passenger.formattedName)
                            .standardFieldLabel()
                    }else{
                        Text(passenger.formattedName)
                            .standardFieldValue()
                    }
                    if self.passenger.contactFormattedName != self.passenger.formattedName {
                        Text(self.passenger.contactFormattedName)
                            .standardInfo()
                    }
                }
                if let first = self.passenger.stats?.first {
                    Spacer()
                    StatsView(stats: first)
                }
            }
        }
        .onAppear(){
            self.fetchImage()
        }
    }
}

struct PassengerRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            PassengerRowView(passenger: Passenger(name: "John"), highlightName : false)
        }
    }
}

