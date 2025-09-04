// MIT License
//
// Copyright (c) 2023 Sanity.io

@testable import Sanity
import XCTest

final class SanityClientPerspectiveTests: XCTestCase {
    func testHashable() {
        let perspective1 = SanityClient.Perspective(rawValue: "1")
        let perspective2 = SanityClient.Perspective(rawValue: "1")
        let perspective3 = SanityClient.Perspective(rawValue: "2")
        XCTAssertEqual(perspective1.hashValue, perspective2.hashValue)
        XCTAssertNotEqual(perspective1.hashValue, perspective3.hashValue)
    }
    
    func testExpressibleByStringLiteral() {
        let perspective: SanityClient.Perspective = "test"
        XCTAssertEqual(perspective.rawValue, "test")
    }
    
    func testLayers() {
        let perspective: SanityClient.Perspective = .layers("1", "2")
        XCTAssertEqual(perspective.rawValue, "1,2")
    }
}
