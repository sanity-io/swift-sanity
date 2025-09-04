// MIT License
//
// Copyright (c) 2023 Sanity.io

@testable import Sanity
import XCTest

final class SanityClientMutationTests: XCTestCase {
    func testTransactionEncoding() {
        let config = SanityClient.Config(
            projectId: "rwmuledy",
            dataset: "prod",
            version: .v1,
            perspective: nil,
            useCdn: false,
            token: nil,
            returnQuery: true
        )
        let transaction = SanityClient.Transaction(config: config, mutations: [
            .createIfNotExists(document: [
                "_id": "one",
                "_type": "some-type",
            ]),
            .createIfNotExists(document: [
                "_id": "two",
                "_type": "some-type",
            ]),
            .createIfNotExists(document: [
                "_id": "three",
                "_type": "some-type",
            ]),
            .createOrReplace(document: [
                "_id": "four",
                "_type": "other",
            ]),
            .delete(documentId: "foo"),
            .patch(documentId: "one", patches: [
                Patch("some-field", operation: .setIfMissing("hello")),
                Patch("new-field", operation: .set("hello")),
                Patch("new-field", operation: .unset),
                Patch("counter", operation: .setIfMissing(0)),
                Patch("counter", operation: .inc(3)),
                Patch("counter", operation: .dec(2)),
                Patch("array", operation: .set([""])),
                Patch("array", operation: .insert("bar", .after)),
                Patch("array[0]", operation: .insert("baz", .before)),
            ]),
            .patch(documentId: "two", patches: [
                Patch("field", operation: .replace("foo")),
                Patch("field", operation: .set("The rabid dog")),
                Patch("aboutADog", operation: .diffMatchPatch("@@ -1,13 +1,12 @@\n The \n-rabid\n+nice\n  dog\n")),
            ]),
            .patch(documentId: "three", patches: [
                // empty
            ]),
            .patch(documentId: "four", patches: [
                Patch("counter", operation: .setIfMissing(0)),
                Patch("counter", operation: .inc(3)),
            ], ifRevisionId: "foo"),
        ], urlSession: URLSession.shared)

        let data = try! transaction.encode()
        let str = String(data: data, encoding: .utf8)
        assertSnapshot(matching: str!)
    }
}
