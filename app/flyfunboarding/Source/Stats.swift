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



import Foundation

struct Stats : Codable {
    var table : String
    var count : Int
    var last : Date? = nil
   
   
    var formattedLast : String? {
        if let last = last {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: last)
        }else{
            return nil
        }
    }
    
    var formattedCount : String {
        let name = table.lowercased()
        var singular = table
        singular.removeLast()
        if self.count == 0 {
            return "no \(name)"
        }else if self.count == 1 {
            return "1 \(singular)"
        }else{
            return "\(self.count) \(name)"
        }
    }
    enum CodingKeys: String, CodingKey {
        case table, count, last
    }
    
    func moreRecent(than : Stats) -> Bool {
        if let a = self.last, let b = than.last {
            return a > b
        }
        return self.last != nil
    }
}
