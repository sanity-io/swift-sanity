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
            version: .v20210325,
            useCdn: true
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
            version: .v1,
            useCdn: false
        )

        XCTAssertEqual(client.config.getURL(path: "/bar/baz").absoluteString, "https://rwmuledy.api.sanity.io/v1/bar/baz")
    }

    func testUseCdn() {
        let client = SanityClient(
            projectId: "rwmuledy",
            dataset: "b",
            version: .v1,
            useCdn: true
        )

        XCTAssertEqual(client.config.getURL(path: "/").absoluteString, "https://rwmuledy.apicdn.sanity.io/v1/")
    }

    func testUseGET() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "b",
            version: .v1,
            useCdn: true,
            token: nil
        )

        let query = String(repeating: "query!", count: 1)

        let request = SanityClient.Query<Any>.apiURL.fetch(query: query, params: [:], config: config).urlRequest

        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testUsePOST() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "b",
            version: .v1,
            useCdn: true,
            token: nil
        )

        let query = String(repeating: "query!", count: 4000)

        let request = SanityClient.Query<Any>.apiURL.fetch(query: query, params: [:], config: config).urlRequest

        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testNoCdnWithToken() {
        let client = SanityClient(projectId: "rwmuledy", dataset: "prod", version: .v1, useCdn: true, token: "yes")
        XCTAssertEqual(client.config.getURL(path: "/").absoluteString, "https://rwmuledy.api.sanity.io/v1/", "Cannot use apicdn when token is set")
    }

    func testConfigInit() {
        let config = SanityClient.Config(projectId: "rwmuledy", dataset: "master", version: .v1, useCdn: false, token: nil)
        let client = SanityClient(config: config)
        XCTAssertEqual(client.config.getURL(path: "/").absoluteString, "https://rwmuledy.api.sanity.io/v1/")
    }
    
    func testImageCodable() throws {
           let image = SanityType.Image.init(id: "123", width: 100, height: 100, format: "jpg", validImage: true, crop: nil, hotspot: nil)
           let data = try JSONEncoder().encode(image)
           print(String(data: data, encoding: .utf8)!)
           let decodedImage = try JSONDecoder().decode(SanityType.Image.self, from: data)
           XCTAssertEqual(decodedImage, image)

       }
}
