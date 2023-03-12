//  MIT License
//
//  Created on 12/03/2023 for flyfunboarding
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
import RZUtilsSwift
import OSLog

extension Airline {
    var authorizationBearer : String {
        return "Bearer \(self.appleIdentifier)"
    }
}

class RemoteService {
    static let shared = RemoteService()
    
    typealias Completion = (Bool) -> Void
    
    func url(point : String, queryItems : [URLQueryItem] = []) -> URL? {
        if let url = URL(string: point, relativeTo: Secrets.shared.flyfunBaseUrl ),
           var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if queryItems.count > 0 {
                components.queryItems = queryItems
            }
            
            return components.url
        }
        return nil
    }
    
    func jsonPostRequest(point: String, data : Codable, airline: Airline? = nil, queryItems: [URLQueryItem]) -> URLRequest? {
        guard let url = self.url(point: point, queryItems: queryItems)
        else { return nil }
        
        do {
            let data = try JSONEncoder().encode(data)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let airline = airline {
                request.setValue(airline.authorizationBearer, forHTTPHeaderField: "Authorization")
            }
            return request
        }catch{
            Logger.net.error("Failed to encode json \(error)")
        }
        return nil
    }
    
    func retrieveCurrentAirline(completion : @escaping (Airline?) -> Void) {
        guard let airline = Settings.shared.currentAirline,
              let airlineId = airline.airlineId,
              let url = self.url(point: "airline/\(airlineId)")
        else { completion(nil); return }
        
        var request = URLRequest(url: url)
        request.setValue(airline.authorizationBearer, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
            else {
                Logger.net.error("Failed \(String(describing: response))")
                completion(nil)
                return
            }
            guard let data = data else { completion(nil); return }
            
            let airline = try? JSONDecoder().decode(Airline.self, from: data)
            completion(airline)
        }.resume()
        
                
    }

    private func retrieveObject<Type : Decodable>(point: String, completion: @escaping (Type?) -> Void) {
        guard let airline = Settings.shared.currentAirline,
              let airlineId = airline.airlineId,
              let url = self.url(point: "airline/\(airlineId)/\(point)")
        else { completion(nil); return }
        
        var request = URLRequest(url: url)
        request.setValue(airline.authorizationBearer, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
            else {
                Logger.net.error("Failed \(String(describing: response))")
                completion(nil)
                return
            }
            guard let data = data else { completion(nil); return }
            
            let aircraft = try? JSONDecoder().decode(Type.self, from: data)
            completion(aircraft)
        }.resume()
    }

    func retrieveAircraftList(completion : @escaping ([Aircraft]?) -> Void) {
        self.retrieveObject(point: "aircraft/list", completion: completion)
    }
    
    func registerAirline(airline : Airline, completion : @escaping (Airline?) -> Void) {
        if let request = self.jsonPostRequest(point: "airline/create", data: airline, airline: airline, queryItems: []) {
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
                else {
                    Logger.net.error("Failed \(String(describing: response))")
                    completion(nil)
                    return
                }
                guard let data = data
                else {
                    Logger.net.error("Didn't get an airline back")
                    completion(nil)
                    return
                }
                let airline = try? JSONDecoder().decode(Airline.self, from: data)
                // if fail, call with nil
                if let airline = airline, let airlineId = airline.airlineId {
                    Logger.net.info("register airline with \(airlineId) for \(airline.appleIdentifier)")
                    Settings.shared.currentAirline = airline
                }
                completion(airline)
            }.resume()
        }
    }
}
