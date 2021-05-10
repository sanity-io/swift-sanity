// MIT License
//
// Copyright (c) 2021 Sanity.io

@testable import Sanity
import XCTest

final class SanityClientTests: XCTestCase {
    func testConfig() {
        let client = SanityClient(
            projectId: "a",
            dataset: "b",
            version: .v20210325
        )

        assert(client.config.projectId == "a")
        assert(client.config.dataset == "b")
        XCTAssertEqual(client.config.version.string, "v2021-03-25")
    }

    // can use getURL() to get API-relative paths
    func testGetURL() {
        let client = SanityClient(
            projectId: "rwmuledy",
            dataset: "b",
            version: .v1
        )

        XCTAssertEqual(client.getURL(path: "/bar/baz").absoluteString, "https://rwmuledy.api.sanity.io/v1/bar/baz")
    }

    func testUseCdn() {
        let client = SanityClient(
            projectId: "rwmuledy",
            dataset: "b",
            version: .v1,
            useCdn: true
        )

        XCTAssertEqual(client.getURL(path: "/").absoluteString, "https://rwmuledy.apicdn.sanity.io/v1/")
    }

    func testNoCdnWithToken() {
        let client = SanityClient(projectId: "rwmuledy", dataset: "prod", version: .v1, token: "yes", useCdn: true)
        XCTAssertEqual(client.getURL(path: "/").absoluteString, "https://rwmuledy.api.sanity.io/v1/", "Cannot use apicdn when token is set")
    }

    func testConfigInit() {
        let config = SanityClient.Config(projectId: "rwmuledy", dataset: "master", version: .v1, token: nil, useCdn: false)
        let client = SanityClient(config: config)
        XCTAssertEqual(client.getURL(path: "/").absoluteString, "https://rwmuledy.api.sanity.io/v1/")
    }
}

final class SanityClientQueryTests: XCTestCase {
    func testQueryURL() {
        let config = SanityClient.Config(projectId: "rwmuledy", dataset: "prod", version: .v1, token: nil, useCdn: false)

        let fetch = SanityClient.Query<String>.apiURL.fetch(query: "*", params: [:], config: config)
        XCTAssertEqual(fetch.urlRequest.url!.absoluteString, "https://rwmuledy.api.sanity.io/v1/data/query/prod?query=*")
    }

    func testQueryURLRequestAuthToken() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "prod",
            version: .v1,
            token: "ABC",
            useCdn: false
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
            token: nil,
            useCdn: false
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
            token: nil,
            useCdn: false
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
