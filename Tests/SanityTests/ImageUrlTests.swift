//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

@testable import Sanity
import XCTest

final class SanityImageUrlTests: XCTestCase {
    func testImageWithInvalidRef() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "Tb9Ew8CXIwaY6R1kjMvI0uRR000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: SanityType.Image.Hotspot(
                height: 0.3,
                width: 0.3,
                x: 0.3,
                y: 0.3
            )
        )

        assert(imageWithNoCropSpecified.validImage == false)

        let url = client.imageURL(imageWithNoCropSpecified)
        assert(url == nil)
    }

    func testImageNoCropWithHotspotSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: SanityType.Image.Hotspot(
                height: 0.3,
                width: 0.3,
                x: 0.3,
                y: 0.3
            )
        )
        let url = client.imageURL(imageWithNoCropSpecified)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg")
    }

    func testImageNoCropWithHotspotWithWidthSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: SanityType.Image.Hotspot(
                height: 0.3,
                width: 0.3,
                x: 0.3,
                y: 0.3
            )
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 100)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?w=100")
    }

    func testImageNoCropWithHotspotWithHeightSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: SanityType.Image.Hotspot(
                height: 0.3,
                width: 0.3,
                x: 0.3,
                y: 0.3
            )
        )
        let url = client.imageURL(imageWithNoCropSpecified, height: 100)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?h=100")
    }

    func testImageNoCropWithHotspotWithTallImageSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: SanityType.Image.Hotspot(
                height: 0.3,
                width: 0.3,
                x: 0.3,
                y: 0.3
            )
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 30, height: 100)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?rect=150,0,900,3000&w=30&h=100")
    }

    func testImageNoCropWithHotspotWithWideImageSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: SanityType.Image.Hotspot(
                height: 0.3,
                width: 0.3,
                x: 0.3,
                y: 0.3
            )
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 100, height: 30)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?rect=0,600,2000,600&w=100&h=30")
    }

    func testImageNoCropNoHotspotSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )
        let url = client.imageURL(imageWithNoCropSpecified)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg")
    }

    func testImageWithWidthNoCropNoHotspotSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 100)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?w=100")
    }

    func testImageWithHeightNoCropNoHotspotSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )
        let url = client.imageURL(imageWithNoCropSpecified, height: 100)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?h=100")
    }

    func testSquareImage() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-1000x1200-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 500, height: 600)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-1000x1200.jpg?w=500&h=600")
    }

    func testImageWithTallImageNoCropNoHotspotSpecified() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 30, height: 100)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?rect=550,0,900,3000&w=30&h=100")
    }

    func testImageWithWideImageNoCropNoHotspotSpecified() throws {
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 100, height: 30)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?rect=0,1200,2000,600&w=100&h=30")
    }

    func testImageWithCropWithHotspotSpecified() throws {
        let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
        let imageWithNoCropSpecified = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: SanityType.Image.Crop(
                bottom: 0.1,
                left: 0.1,
                right: 0.1,
                top: 0.1
            ),
            hotspot: SanityType.Image.Hotspot(
                height: 0.3,
                width: 0.3,
                x: 0.3,
                y: 0.3
            )
        )
        let url = client.imageURL(imageWithNoCropSpecified, width: 30, height: 100)
        assert(url!.absoluteString == "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?rect=240,300,720,2400&w=30&h=100")
    }
}
