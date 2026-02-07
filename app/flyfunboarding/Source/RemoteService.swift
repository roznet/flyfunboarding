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

extension String {
    var shortenedPoint : String {
        let components = self.components(separatedBy: "/").map { $0.count < 12 ? $0 : $0.prefix(5)+".."+$0.suffix(5) }
        return components.joined(separator: "/")
    }
}

class RemoteService {
    static let shared = RemoteService()
   
    init() {
        Logger.net.info("Connected to \(Secrets.shared.flyfunApiUrl) ")
    }
    static let decoder : JSONDecoder = {
        let rv = JSONDecoder()
        rv.dateDecodingStrategy = .iso8601
        return rv
    }()
    
    static let encoder : JSONEncoder = {
        let rv = JSONEncoder()
        rv.dateEncodingStrategy = .iso8601
        return rv
    }()
    
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
        let baseUrl = Secrets.shared.flyfunApiUrl
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
            let data = try RemoteService.encoder.encode(data)
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
   
    private func validateResponse(data : Data?, response: URLResponse?, error : Error?) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse
        else {
            Logger.net.error("Failed with error \(String(describing: error))")
            return false
        }
        
        if httpResponse.statusCode != 200 {
            if let data = data, let message = String(data: data, encoding: .utf8) {
                Logger.net.error( "Failed with status \(httpResponse.statusCode) and message \(message)")
            }else{
                Logger.net.error( "Failed with status \(httpResponse.statusCode)")
            }
            return false
        }
        
        return true
    }
    private func registerObject<Type:Codable>(point: String, object: Codable, requireAirline : Bool = true, completion: @escaping (Type?) -> Void) {
        var airline : Airline? = nil
        if requireAirline {
            airline = Settings.shared.currentAirline
            
            guard airline != nil
            else { completion(nil); return }
        }
        
        guard let request = self.jsonPostRequest(point: point, data: object, airline: airline, queryItems: []) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard self.validateResponse(data: data, response: response, error: error)
            else {
                completion(nil)
                return
            }
            guard let data = data else { completion(nil); return }
           
            do {
                let retrieved = try RemoteService.decoder.decode(Type.self, from: data)
                Logger.net.info("registered successful \(point.shortenedPoint)")
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
            guard self.validateResponse(data: data, response: response, error: error)
            else {
                completion(nil)
                return
            }
            guard let data = data else { completion(nil); return }
           
            do {
                let retrieved = try RemoteService.decoder.decode(Type.self, from: data)
                Logger.net.info("retrieved successful \(point.shortenedPoint)")
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

    private func deleteObject(point : String, completion: @escaping (Bool) -> Void) {
        guard let airline = Settings.shared.currentAirline,
              let url = self.url(point: point)
        else { completion(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(airline.authorizationBearer, forHTTPHeaderField: "Authorization")
        Logger.net.info("Delete \(url)")
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard self.validateResponse(data: data, response: response, error: error)
            else {
                completion(false)
                return
            }

            Logger.net.info("deleted successful \(point.shortenedPoint)")
            completion(true)
        }.resume()
    }
    

    
    //MARK: - Airline
    func registerAirline(airline : Airline, completion : @escaping (Airline?) -> Void) {
        self.registerObject(point: "airline/create", object: airline, requireAirline: false) { (airline : Airline?) in
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
    func retrieveCurrentAirline(completion : @escaping (Airline?) -> Void) {
        guard let airline = Settings.shared.currentAirline,
              let airlineIdentifier = airline.airlineIdentifier
        else { completion(nil); return }
        
        self.retrieveObject(point: "airline/\(airlineIdentifier)", completion: completion)
    }
    func retrieveAndCheckCurrentAirlineKeys(){
        guard let point = self.point(api: "keys", airline: Settings.shared.currentAirline) else { return }
        self.retrieveObject(point: point) {
            (keys : Airline.Keys?) in
            if let keys = keys {
                let existing = Settings.shared.airlinePublicKey
                // if we have keys, check if they changed (they shouldn't)
                if existing == "" {
                    // if no existing keys save the one we have
                    Logger.app.info("Registered new public key")
                    Settings.shared.airlinePublicKey = keys.publicKey
                }
                else if keys.publicKey != existing {
                    Logger.app.error("Keys changed!")
                    // We won't do anything, this is not intended to be the most secure app
                    // But here we should invalidate validation of tickets,
                    Settings.shared.airlinePublicKey = keys.publicKey
                }
            }
        }
    }
    func deleteCurrentAirline(completion: @escaping (Bool) ->Void) {
        guard let airline = Settings.shared.currentAirline,
              let airlineIdentifier = airline.airlineIdentifier
        else { completion(false); return }
        self.deleteObject(point: "airline/\(airlineIdentifier)", completion: completion)
    }
    func retrieveAirlineSettings(completion: @escaping (Airline.Settings?) -> Void){
        guard let airline = Settings.shared.currentAirline,
              let airlineIdentifier = airline.airlineIdentifier
        else { completion(Airline.Settings()); return }
        self.retrieveObject(point: "airline/\(airlineIdentifier)/settings", completion: completion)
    }
    func updateAirlineSettings(settings : Airline.Settings, completion : @escaping (Airline.Settings?) -> Void) {
        guard let airline = Settings.shared.currentAirline,
              let airlineIdentifier = airline.airlineIdentifier
        else { completion(nil); return }
        self.registerObject(point: "airline/\(airlineIdentifier)/settings", object: settings, completion: completion)
    }
   
    //MARK: - Aircrafts
    func retrieveAircraftList(completion : @escaping ([Aircraft]?) -> Void) {
        guard let point = self.point(api: "aircraft/list", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.retrieveObject(point: point, completion: completion)
    }
    func registerAircraft(aircraft: Aircraft, completion: @escaping (Aircraft?) -> Void) {
        guard let point = self.point(api: "aircraft/create", airline: Settings.shared.currentAirline) else { return }
        self.registerObject(point: point, object: aircraft, completion: completion)
    }
    func deleteAircraft(aircraft: Aircraft, completion: @escaping (Bool)->Void) {
        guard let aircraftId = aircraft.aircraft_identifier
        else { completion(false); return }
        guard let point = self.point(api: "aircraft/\(aircraftId)", airline: Settings.shared.currentAirline) else { completion(false); return }
        self.deleteObject(point: point, completion: completion)
    }

    //MARK: - Passengers
    func retrievePassengerList(completion : @escaping ([Passenger]?) -> Void) {
        guard let point = self.point(api: "passenger/list", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.retrieveObject(point: point, completion: completion)
    }

    func registerPassenger(passenger : Passenger, completion: @escaping (Passenger?) -> Void) {
        guard let point = self.point(api: "passenger/create", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.registerObject(point: point, object: passenger, completion: completion)
    }
    
    //MARK: - Flights
    func retrieveFlightList(aircraft : Aircraft? = nil, completion : @escaping ([Flight]?) -> Void) {
        let api = aircraft?.aircraft_identifier == nil ? "flight/list" : "aircraft/\(aircraft!.aircraft_identifier!)/flights"
        
        guard let point = self.point(api: api, airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.retrieveObject(point: point, completion: completion)
    }
    func scheduleFlight(flight: Flight, completion: @escaping (Flight?) -> Void) {
        guard let aircraftId = flight.aircraft.aircraft_identifier
        else { completion(nil); return }
        guard let point = self.point(api: "flight/plan/\(aircraftId)", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.registerObject(point: point, object: flight, completion: completion)
    }
    func amendFlight(flight: Flight, completion: @escaping (Flight?)->Void) {
        guard let flightId = flight.flight_identifier
        else { completion(nil); return }
        guard let point = self.point(api: "flight/amend/\(flightId)", airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.registerObject(point: point, object: flight, completion: completion)
    }
    func deleteFlight(flight: Flight, completion: @escaping (Bool)->Void) {
        guard let flightId = flight.flight_identifier
        else { completion(false); return }
        guard let point = self.point(api: "flight/\(flightId)", airline: Settings.shared.currentAirline) else { completion(false); return }
        self.deleteObject(point: point, completion: completion)
    }


    //MARK: - Tickets
    func retrieveTicketList(flight: Flight? = nil, passenger: Passenger? = nil, completion : @escaping ([Ticket]?) -> Void) {
        var api = "ticket/list"
        if let flight_identifier = flight?.flight_identifier {
            api = "flight/\(flight_identifier)/tickets"
        }else if let passenger_identifier = passenger?.passenger_identifier {
            api = "passenger/\(passenger_identifier)/tickets"
        }
        
        guard let point = self.point(api: api, airline: Settings.shared.currentAirline) else { completion(nil); return }
        self.retrieveObject(point: point, completion: completion)
    }
    func deleteTicket(ticket: Ticket, completion: @escaping (Bool)->Void) {
        guard let ticketId = ticket.ticket_identifier
        else { completion(false); return }
        guard let point = self.point(api: "ticket/\(ticketId)", airline: Settings.shared.currentAirline) else { completion(false); return }
        self.deleteObject(point: point, completion: completion)
    }
    
    func issueTicket(ticket : Ticket, completion: @escaping (Ticket?)->Void){
        guard let flightId = ticket.flight.flight_identifier,
              let passengerId = ticket.passenger.passenger_identifier
        else { completion(nil); return }
        guard let point = self.point(api: "ticket/issue/\(flightId)/\(passengerId)", airline: Settings.shared.currentAirline)
        else { completion(nil); return }
        self.registerObject(point: point, object: ticket, completion: completion)
    }
    
    func verifyTicket(signature: Ticket.Signature, completion : @escaping (Ticket?) -> Void) {
        guard let point = self.point(api: "ticket/verify", airline: Settings.shared.currentAirline)
        else { completion(nil); return }
        self.registerObject(point: point, object: signature, completion: completion)
    }
}
