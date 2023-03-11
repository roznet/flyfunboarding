//
//  Secrets.swift
//  flyfunboarding
//
//  Created by Brice Rosenzweig on 11/03/2023.
//

import Foundation
import RZUtilsSwift

extension Secrets {
    public var flyfunBaseUrl : URL { return URL(string: self["flyfun_api_url"] ?? "")! }
}
