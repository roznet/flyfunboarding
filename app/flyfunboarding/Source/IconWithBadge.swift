//  MIT License
//
//  Created on 24/03/2023 for flyfunboarding
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

struct IconWithBadge: View {
    var name : String
    var badge : String
    var scale : CGFloat = 1.0/2.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                self.badgeView(size: geometry.size)
                           
                
            }
        }
    }
    
    
    func badgeView(size: CGSize) -> some View {
       return
                Image(systemName: badge)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width * scale , height: size.height * scale )
                    .offset(x: -size.width * scale , y: size.height * scale)
    }
}

struct IconWithBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            IconWithBadge(name: "person.fill", badge: "plus.circle.fill")
                .frame(width: 50.0, height: 50.0)
                .padding()
            IconWithBadge(name: "network", badge: "plus.circle.fill")
                .frame(width: 50.0, height: 50.0)
                .padding()
            IconWithBadge(name: "airplane", badge: "plus.circle.fill")
                .frame(width: 50.0, height: 50.0)
                .padding()
        }
            
           
    }
}
