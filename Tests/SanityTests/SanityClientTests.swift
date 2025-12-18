// MIT License
//
// Copyright (c) 2023 Sanity.io

@testable import Sanity
import XCTest

final class SanityClientTests: XCTestCase {
    func testConfig() {
        let client = SanityClient(
            projectId: "a",
            dataset: "b",
            version: .v20210325,
            perspective: .published,
            useCdn: true,
            returnQuery: false
        )

        XCTAssertEqual(client.config.projectId, "a")
        XCTAssertEqual(client.config.dataset, "b")
        XCTAssertEqual(client.config.version.string, "v2021-03-25")
        XCTAssertEqual(client.config.perspective, .published)
        XCTAssertEqual(client.config.returnQuery, false)
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
            perspective: nil,
            useCdn: true,
            token: nil,
            returnQuery: true
        )

        let query = String(repeating: "query!", count: 1)

        let request = SanityClient.Query<Any>.apiURL.fetch(query: query, params: [:], config: config).urlRequest

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, "https://rwmuledy.apicdn.sanity.io/v1/data/query/b?query=query!")
        XCTAssertNil(request.httpBody)
    }

    func testUsePOST() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "b",
            version: .v1,
            perspective: nil,
            useCdn: true,
            token: nil,
            returnQuery: true
        )

        let query = String(repeating: "query!", count: 4000)

        let request = SanityClient.Query<Any>.apiURL.fetch(query: query, params: [:], config: config).urlRequest

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://rwmuledy.apicdn.sanity.io/v1/data/query/b")
        XCTAssertEqual(request.httpBody, Data("{\"query\":\"\(query)\"}".utf8))
    }

    func testCdnWithToken() {
        let client = SanityClient(projectId: "rwmuledy", dataset: "prod", version: .v1, useCdn: true, token: "yes")
        XCTAssertEqual(client.config.getURL(path: "/").absoluteString, "https://rwmuledy.apicdn.sanity.io/v1/", "Can use apicdn when token is set")
    }

    func testConfigInit() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "master",
            version: .v1,
            perspective: nil,
            useCdn: false,
            token: nil,
            returnQuery: true
        )
        let client = SanityClient(config: config)
        XCTAssertEqual(client.config.getURL(path: "/").absoluteString, "https://rwmuledy.api.sanity.io/v1/")
    }

    func testImageCodable() throws {
        let image = SanityType.Image(id: "123", width: 100, height: 100, format: "jpg", validImage: true, crop: nil, hotspot: nil)
        let data = try JSONEncoder().encode(image)
        print(String(data: data, encoding: .utf8)!)
        let decodedImage = try JSONDecoder().decode(SanityType.Image.self, from: data)
        XCTAssertEqual(decodedImage, image)
    }

    func testFileURL() {
        let file = SanityType.File(asset: .init(_ref: "foo-bar-png", _type: "file"))
        let client = SanityClient(projectId: "rwmuledy", dataset: "some-dataset", version: .v1, useCdn: false)
        let url = client.fileURL(file)!
        XCTAssertEqual(url.absoluteString, "https://cdn.sanity.io/files/rwmuledy/some-dataset/bar.png")
    }
    
    func testPerspective() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "master",
            version: .v20250219,
            perspective: .drafts,
            useCdn: true,
            token: nil,
            returnQuery: true
        )
        let request = SanityClient.Query<Any>.apiURL.fetch(query: "query!", params: [:], config: config).urlRequest
        XCTAssertEqual(request.url?.absoluteString, "https://rwmuledy.apicdn.sanity.io/v2025-02-19/data/query/master?query=query!&perspective=drafts")
    }
    
    func testReturnQuery() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "master",
            version: .v20250219,
            perspective: nil,
            useCdn: true,
            token: nil,
            returnQuery: false
        )
        let request = SanityClient.Query<Any>.apiURL.fetch(query: "query!", params: [:], config: config).urlRequest
        XCTAssertEqual(request.url?.absoluteString, "https://rwmuledy.apicdn.sanity.io/v2025-02-19/data/query/master?query=query!&returnQuery=false")
    }
}
