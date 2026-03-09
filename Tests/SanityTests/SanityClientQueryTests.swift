// MIT License
//
// Copyright (c) 2023 Sanity.io

@testable import Sanity
import XCTest

final class SanityClientQueryTests: XCTestCase {
    func testQueryURL() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "prod",
            version: .v1,
            perspective: .raw,
            useCdn: false,
            token: nil,
            returnQuery: false
        )

        let fetch = SanityClient.Query<String>.apiURL.fetch(query: "*", params: [:], config: config)
        XCTAssertEqual(fetch.urlRequest.url?.absoluteString, "https://rwmuledy.api.sanity.io/v1/data/query/prod?query=*&perspective=raw&returnQuery=false")
    }

    func testQueryURLRequestAuthToken() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "prod",
            version: .v1,
            perspective: nil,
            useCdn: false,
            token: "ABC",
            returnQuery: true
        )

        let fetch = SanityClient.Query<String>.apiURL.fetch(
            query: "*",
            params: [:],
            config: config
        )

        XCTAssertEqual(
            fetch.urlRequest.value(forHTTPHeaderField: "Authorization"),
            "Bearer ABC"
        )

        let listen = SanityClient.Query<String>.apiURL.listen(
            query: "*",
            params: [:],
            config: config,
            includeResult: nil,
            includePreviousRevision: nil,
            visibility: nil
        )

        XCTAssertEqual(
            listen.urlRequest.value(forHTTPHeaderField: "Authorization"),
            "Bearer ABC"
        )
    }

    func testOverrideDefaultParams() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "prod",
            version: .v1,
            perspective: nil,
            useCdn: false,
            token: nil,
            returnQuery: true
        )

        let listen = SanityClient.Query<String>.apiURL.listen(
            query: "*",
            params: [:],
            config: config,
            includeResult: false,
            includePreviousRevision: nil,
            visibility: nil
        )

        let url = listen.urlRequest.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        let query = components.queryItems?.first(where: { $0.name == "query" })?.value
        XCTAssertEqual(query, "*")

        let includeResult = components.queryItems?.first(where: { $0.name == "includeResult" })?.value
        XCTAssertEqual(includeResult, "false")
    }

    func testAddParams() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "prod",
            version: .v1,
            perspective: nil,
            useCdn: false,
            token: nil,
            returnQuery: true
        )

        let fetch = SanityClient.Query<String>.apiURL.fetch(
            query: "*",
            params: ["kustom": 29, "another": "one"],
            config: config
        )

        let url = fetch.urlRequest.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        let kustom = components.queryItems?.first(where: { $0.name == "$kustom" })?.value
        XCTAssertEqual(kustom, "29")

        let another = components.queryItems?.first(where: { $0.name == "$another" })?.value
        XCTAssertEqual(another, "\"one\"")
    }

    func testJsonEncodeString() {
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode("hello"), "\"hello\"")
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode("with \"quotes\""), "\"with \\\"quotes\\\"\"")
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode("new\nline"), "\"new\\nline\"")
    }

    func testJsonEncodeNumber() {
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode(42), "42")
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode(3.5), "3.5")
    }

    func testJsonEncodeBool() {
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode(true), "true")
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode(false), "false")
    }

    func testJsonEncodeNull() {
        XCTAssertEqual(SanityClient.Query<String>.apiURL.jsonEncode(NSNull()), "null")
    }

    func testJsonEncodeArray() {
        let result = SanityClient.Query<String>.apiURL.jsonEncode([1, 2, 3])
        XCTAssertEqual(result, "[1,2,3]")

        let doubles = SanityClient.Query<String>.apiURL.jsonEncode([0.5, 1.5, 2.5])
        XCTAssertEqual(doubles, "[0.5,1.5,2.5]")
    }

    func testJsonEncodeObject() {
        let result = SanityClient.Query<String>.apiURL.jsonEncode(["title": "hello"])
        XCTAssertEqual(result, "{\"title\":\"hello\"}")
    }

    func testParamsSerializedAsJson() {
        let config = SanityClient.Config(
            projectId: "a",
            dataset: "b",
            version: .v1,
            perspective: nil,
            useCdn: false,
            token: nil,
            returnQuery: true
        )

        let fetch = SanityClient.Query<String>.apiURL.fetch(
            query: "*",
            params: ["lang": "en-us", "limit": 10, "active": true, "tags": ["a", "b"], "empty": NSNull()],
            config: config
        )

        let url = fetch.urlRequest.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        func param(_ name: String) -> String? {
            components.queryItems?.first(where: { $0.name == "$\(name)" })?.value
        }

        XCTAssertEqual(param("lang"), "\"en-us\"")
        XCTAssertEqual(param("limit"), "10")
        XCTAssertEqual(param("active"), "true")
        XCTAssertEqual(param("tags"), "[\"a\",\"b\"]")
        XCTAssertEqual(param("empty"), "null")
    }
}
