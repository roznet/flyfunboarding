//  MIT License
//
//  Created on 09/04/2023 for flyfunboarding
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
import CryptoKit

struct Signature {
    let publicKey : SecKey
   
    enum Status {
        case verified
        case invalidSignature
        case incorrectSignature
    }
    init?(publicKeyPemString: String) {
        if let key = Self.publicKeyFromPEM(publicKeyPemString) {
            self.publicKey = key
        }else{
            return nil
        }
    }

    static private func publicKeyFromPEM(_ pemString: String) -> SecKey? {
        let keyString = pemString
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let keyData = Data(base64Encoded: keyString) else {
            return nil
        }

        let keyDict: [NSString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: NSNumber(value: 2048),
            kSecReturnPersistentRef: true
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, keyDict as CFDictionary, &error) else {
            return nil
        }

        return secKey
    }

    func verifySignature(base64Signature: String, string: String, encoding: String.Encoding = .utf8) -> Status {
        if let data = string.data(using: encoding) {
            return self.verifySignature(base64Signature: base64Signature, data: data)
        }
        return .invalidSignature
    }
    func verifySignature(base64Signature: String, data: Data) -> Status {
        guard let signatureData = Data(base64Encoded: base64Signature) else {
            return .invalidSignature
        }
        let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
        
        guard SecKeyIsAlgorithmSupported(publicKey, .verify, algorithm) else {
            return .invalidSignature
        }
        
        var error: Unmanaged<CFError>?
        
        let isVerified = SecKeyVerifySignature(publicKey, algorithm, data as CFData, signatureData as CFData, &error)
        
        if error != nil {
            return .incorrectSignature
        }
        return isVerified ? .verified : .incorrectSignature
    }


}
