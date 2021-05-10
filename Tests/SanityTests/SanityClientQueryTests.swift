//
//  File.swift
//  
//
//  Created by Sindre Gulseth on 10/05/2021.
//

@testable import Sanity
import XCTest

final class SanityClientQueryTests: XCTestCase {
    func testQueryURL() {
        let config = SanityClient.Config(projectId: "rwmuledy", dataset: "prod", version: .v1, useCdn: false, token: nil)

        let fetch = SanityClient.Query<String>.apiURL.fetch(query: "*", params: [:], config: config)
        XCTAssertEqual(fetch.urlRequest.url!.absoluteString, "https://rwmuledy.api.sanity.io/v1/data/query/prod?query=*")
    }

    func testQueryURLRequestAuthToken() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "prod",
            version: .v1,
            useCdn: false,
            token: "ABC"
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
            config: config
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
            useCdn: false,
            token: nil
        )

        let listen = SanityClient.Query<String>.apiURL.listen(
            query: "*",
            params: ["includeResult": false],
            config: config
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
            useCdn: false,
            token: nil
        )

        let fetch = SanityClient.Query<String>.apiURL.fetch(
            query: "*",
            params: ["kustom": 29, "another": "one"],
            config: config
        )

        let url = fetch.urlRequest.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        let kustom = components.queryItems?.first(where: { $0.name == "kustom" })?.value
        XCTAssertEqual(kustom, "29")

        let another = components.queryItems?.first(where: { $0.name == "another" })?.value
        XCTAssertEqual(another, "one")
    }
}
