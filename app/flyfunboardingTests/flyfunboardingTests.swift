//
//  flyfunboardingTests.swift
//  flyfunboardingTests
//
//  Created by Brice Rosenzweig on 10/03/2023.
//

import XCTest
@testable import flyfunboarding

final class flyfunboardingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSamples() throws {
        let tickets = Samples.tickets
        XCTAssertGreaterThan(tickets.count, 0)
        let aircrafts = Samples.aircrafts
        XCTAssertGreaterThan(aircrafts.count, 0)
        let passengers = Samples.passengers
        XCTAssertGreaterThan(passengers.count, 0)
        let flights = Samples.flights
        XCTAssertGreaterThan(flights.count, 0)
        
    }

    

}
