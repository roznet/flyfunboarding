//  MIT License
//
//  Created on 09/04/2023 for flyfunboardingTests
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



import XCTest
@testable import flyfunboarding

final class signatureTests: XCTestCase {
    
    struct Input : Codable {
        var id : String
        var signature : String
        var verified : Bool
        var publicKey : String
        var data : String
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSignature() throws {
        if let jsonFile = Bundle(for: type(of: self)).url(forResource: "test_signature", withExtension: "json") {
            let data = try Data(contentsOf: jsonFile)
            let decoder = JSONDecoder()
            let input = try decoder.decode(Input.self, from: data)
            if let sign = SignatureVerifier(publicKeyPemString: input.publicKey),
               let data = input.data.data(using: .utf8),
               let badData = "Bad".data(using: .utf8){
                XCTAssertEqual( sign.verifySignature(base64Signature: input.signature, data: data), .verified)
                XCTAssertEqual( sign.verifySignature(base64Signature: input.signature, string: input.data), .verified)
                XCTAssertNotEqual( sign.verifySignature(base64Signature: input.signature, data: badData), .verified)
            }else{
                XCTAssertTrue(false)
            }
        }else{
            XCTAssertTrue(false)
        }
    }
    
    func testValidate() throws {
        guard let keysFile = Bundle(for: type(of: self)).url(forResource: "sample_keys", withExtension: "json"),
              let sampleOldFile = Bundle(for: type(of: self)).url(forResource: "sample_validate_old", withExtension: "json"),
            let sampleNewFile = Bundle(for: type(of: self)).url(forResource: "sample_validate_new", withExtension: "json")
              
        else { XCTAssertTrue(false); return }
        let sampleOld = try JSONDecoder().decode(Ticket.Signature.self, from: try Data(contentsOf: sampleOldFile))
        let sampleNew = try JSONDecoder().decode(Ticket.Signature.self, from: try Data(contentsOf: sampleNewFile))
        let keys = try JSONDecoder().decode(Airline.Keys.self, from: try Data(contentsOf: keysFile))
        
        guard let verifier = keys.signatureVerifier else { XCTAssertTrue(false); return }
        XCTAssertFalse(sampleOld.canVerify)
        XCTAssertTrue(sampleNew.canVerify)
        let checkNew = sampleNew.verify(with: verifier)
        XCTAssertEqual(checkNew, .verified)
    }
}
