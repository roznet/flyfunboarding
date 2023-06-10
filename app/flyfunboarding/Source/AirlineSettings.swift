//  MIT License
//
//  Created on 04/06/2023 for flyfunboarding
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
import SwiftUI

extension Airline {
    struct Settings : Codable {
        var background : String
        var foreground : String
        var label : String
        var customLabelEnabled : Bool
        var customLabel : String
        
        var backgroundColor : Color {
            get { return Color(rgb: self.background) }
            set { self.background = newValue.rgb }
        }
        
        var foregroundcolor : Color {
            get { return Color(rgb: self.foreground) }
            set { self.foreground = newValue.rgb }
        }
        
        var labelColor : Color {
            get { return Color(rgb: self.label) }
            set { self.label = newValue.rgb }
        }
        
        enum CodingKeys: String, CodingKey {
            case background = "backgroundColor"
            case foreground = "foregroundColor"
            case label = "labelColor"
            case customLabelEnabled = "customLabelEnabled"
            case customLabel = "customLabel"
        }
        
        init() {
            self.background = "rgb(189,144,71)"
            self.label = "rgb(255,255,255)"
            self.foreground = "rgb(0,0,0)"
            self.customLabel = "Boarding Group"
            self.customLabelEnabled = true
        }
       
        init(backgroundColor: Color, foregroundColor: Color, labelColor: Color, customLabel: String, customLabelEnabled: Bool) {
            self.background = backgroundColor.rgb
            self.foreground = foregroundColor.rgb
            self.label = labelColor.rgb
            self.customLabel = customLabel
            self.customLabelEnabled = customLabelEnabled
        }
    }
}
