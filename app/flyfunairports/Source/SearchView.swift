//  MIT License
//
//  Created on 10/09/2023 for flyfunairports
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

struct SearchView: View {
    @StateObject var search : LocationSearch = LocationSearch()
    @State var showSearch : Bool = true
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search", text: $search.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color(.systemBackground))
                if self.showSearch {
                    Button {
                        self.showSearch = false
                    } label: {
                        Image(systemName: "chevron.up.circle")
                    }
                }else{
                    Button {
                        self.showSearch = true
                    } label: {
                        Image(systemName: "chevron.down.circle")
                    }
                }
            }
            if self.showSearch {
                VStack {
                    List( self.search.searchResults, id: \.self ) {
                        res in
                        SearchCompletionView(searchCompletion: res)
                    }
                    List( self.search.airportResults) {
                        res in
                        AirportRowView(airport: res)
                    }
                }
            }
        }
        .cornerRadius(5)
    }
}

#Preview {
    SearchView()
}
