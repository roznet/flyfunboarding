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
        print( tickets)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
