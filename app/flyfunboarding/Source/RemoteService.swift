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
    
   //MARK: - url and point helpers
    private func point(api : String, airline: Airline? = nil) -> String? {
        if let airlineIdentifier = airline?.airlineIdentifier {
            // if we have airline need valid number
            let rv = ("airline/\(airlineIdentifier)/" as NSString).appendingPathComponent(api)
            return rv
        }else{
            return api
        }
    }
    
    private func url(point : String, queryItems : [URLQueryItem] = []) -> URL? {
        let baseUrl = Secrets.shared.flyfunBaseUrl
        if let url = URL(string: point, relativeTo: baseUrl ),
           var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if queryItems.count > 0 {
                components.queryItems = queryItems
            }
            
            return components.url
        }
        return nil
    }
    //MARK: - request helpers
    private func jsonPostRequest(point: String, data : Codable, airline: Airline? = nil, queryItems: [URLQueryItem]) -> URLRequest? {
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
    
    private func registerObject<Type:Codable>(point: String, object: Type, requireAirline : Bool = true, completion: @escaping (Type?) -> Void) {
        var airline : Airline? = nil
        if requireAirline {
            airline = Settings.shared.currentAirline
            
            guard airline != nil
            else { completion(nil); return }
        }
        
        guard let request = self.jsonPostRequest(point: point, data: object, airline: airline, queryItems: []) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
            else {
                Logger.net.error("Failed \(String(describing: response))")
                completion(nil)
                return
            }
            guard let data = data else { completion(nil); return }
           
            do {
                let retrieved = try JSONDecoder().decode(Type.self, from: data)
                Logger.net.info("registered successful \(point)")
                completion(retrieved)
            }catch{
                Logger.net.error("Failed to decode \(point) with error: \(error)")
                if let str = String(data: data, encoding: .utf8) {
                    Logger.net.info("Data: \(str)")
                }
                completion(nil)
            }
        }.resume()
    }
    private func retrieveObject<Type : Decodable>(point: String, completion: @escaping (Type?) -> Void) {
        guard let airline = Settings.shared.currentAirline,
              let url = self.url(point: point)
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
           
            do {
                let retrieved = try JSONDecoder().decode(Type.self, from: data)
                Logger.net.info("retrieved successful \(point)")
                completion(retrieved)
            }catch{
                Logger.net.error("Failed to decode \(point) with error: \(error)")
                if let str = String(data: data, encoding: .utf8) {
                    Logger.net.info("Data: \(str)")
                }
                completion(nil)
            }
        }.resume()
    }
    

    
    //MARK: - api calls
    func retrieveCurrentAirline(completion : @escaping (Airline?) -> Void) {
        guard let airline = Settings.shared.currentAirline,
              let airlineIdentifier = airline.airlineIdentifier
        else { completion(nil); return }
        
        self.retrieveObject(point: "airline/\(airlineIdentifier)", completion: completion)
    }
    
    func retrieveAircraftList(completion : @escaping ([Aircraft]?) -> Void) {
        guard let point = self.point(api: "aircraft/list", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.retrieveObject(point: point, completion: completion)
    }

    func retrievePassengerList(completion : @escaping ([Passenger]?) -> Void) {
        guard let point = self.point(api: "passenger/list", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.retrieveObject(point: point, completion: completion)
    }

    func registerPassenger(passenger : Passenger, completion: @escaping (Passenger?) -> Void) {
        guard let point = self.point(api: "passenger/create", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.registerObject(point: point, object: passenger, completion: completion)
    }
    
    func registerAircraft(aircraft: Aircraft, completion: @escaping (Aircraft?) -> Void) {
        guard let point = self.point(api: "aircraft/create", airline: Settings.shared.currentAirline) else { return }
        self.registerObject(point: point, object: aircraft, completion: completion)
    }
    
    func registerAirline(airline : Airline, completion : @escaping (Airline?) -> Void) {
        self.registerObject(point: "airline/create", object: airline, requireAirline: false) { airline in
            if let airline = airline, let airlineId = airline.airlineId {
                Logger.net.info("register airline with \(airlineId) for \(airline.appleIdentifier)")
                Settings.shared.currentAirline = airline
            }else{
                Logger.net.info("Failed to register")
                Settings.shared.currentAirline = nil
            }
            completion(airline)
        }
    }
   
    func signOut() {
        Settings.shared.currentAirline = nil
    }

            
}
