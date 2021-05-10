// MIT License
//
// Copyright (c) 2021 Sanity.io

@testable import Sanity
import XCTest

let hotspotImage = SanityType.Image(
    asset: SanityType.Ref(
        _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
        _type: "reference"
    ),
    crop: nil,
    hotspot: SanityType.Image.Hotspot(
        width: 0.3,
        height: 0.3,
        x: 0.3,
        y: 0.3
    )
)

let noHotspotNoCropImage = SanityType.Image(
    asset: SanityType.Ref(
        _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
        _type: "reference"
    ),
    crop: nil,
    hotspot: nil
)

let client = SanityClient(projectId: "zp7mbokg", dataset: "production")

final class SanityImageUrlTests: XCTestCase {
    func testImageWithInvalidRef() throws {
        let image = SanityType.Image(
            asset: SanityType.Ref(
                // _ref here is invalid
                _ref: "Tb9Ew8CXIwaY6R1kjMvI0uRR000x3000-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )

        assert(image.validImage == false)
        let url = client.imageURL(image).URL()
        assert(url == nil)
    }

    func testImageNoCropWithHotspotSpecified() throws {
        let image = hotspotImage
        let url = client.imageURL(image).URL()
        let expect = "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg"
        assert(url!.absoluteString == expect)
    }

    func testImageNoCropWithHotspotWithWidthSpecified() throws {
        let image = hotspotImage
        let url = client.imageURL(image)
            .width(100)
            .URL()
        assert(url!.query == "w=100")
    }

    func testImageNoCropWithHotspotWithHeightSpecified() throws {
        let image = hotspotImage
        let url = client.imageURL(image)
            .height(100)
            .URL()
        assert(url!.query == "h=100")
    }

    func testImageNoCropWithHotspotWithTallImageSpecified() throws {
        let image = hotspotImage
        let url = client.imageURL(image)
            .width(30)
            .height(100)
            .URL()
        assert(url!.query == "rect=150,0,900,3000&w=30&h=100")
    }

    func testImageNoCropWithHotspotWithWideImageSpecified() throws {
        let image = hotspotImage
        let url = client.imageURL(image)
            .width(100)
            .height(30)
            .URL()
        assert(url!.query == "rect=0,600,2000,600&w=100&h=30")
    }

    func testImageNoCropNoHotspotSpecified() throws {
        let image = noHotspotNoCropImage
        let url = client.imageURL(image).URL()
        let expect = "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg"
        assert(url!.absoluteString == expect)
    }

    func testImageWithWidthNoCropNoHotspotSpecified() throws {
        let image = noHotspotNoCropImage
        let url = client.imageURL(image)
            .width(100)
            .URL()
        assert(url!.query == "w=100")
    }

    func testImageWithHeightNoCropNoHotspotSpecified() throws {
        let image = noHotspotNoCropImage
        let url = client.imageURL(image)
            .height(100)
            .URL()

        assert(url!.query == "h=100")
    }

    func testSquareImage() throws {
        let image = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-1000x1200-jpg",
                _type: "reference"
            ),
            crop: nil,
            hotspot: nil
        )
        let url = client.imageURL(image)
            .width(500)
            .height(600)
            .URL()

        let exp = "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-1000x1200.jpg?w=500&h=600"
        assert(url!.absoluteString == exp)
    }

    func testImageWithTallImageNoCropNoHotspotSpecified() throws {
        let image = noHotspotNoCropImage
        let url = client.imageURL(image)
            .width(30)
            .height(100)
            .URL()

        assert(url!.query == "rect=550,0,900,3000&w=30&h=100")
    }

    func testImageWithWideImageNoCropNoHotspotSpecified() throws {
        let image = noHotspotNoCropImage
        let url = client.imageURL(image)
            .width(100)
            .height(30)
            .URL()
        assert(url!.query == "rect=0,1200,2000,600&w=100&h=30")
    }

    func testImageWithCropWithHotspotSpecified() throws {
        let image = SanityType.Image(
            asset: SanityType.Ref(
                _ref: "image-Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000-jpg",
                _type: "reference"
            ),
            crop: SanityType.Image.Crop(
                bottom: 0.1,
                left: 0.1,
                top: 0.1,
                right: 0.1
            ),
            hotspot: SanityType.Image.Hotspot(
                width: 0.3,
                height: 0.3,
                x: 0.3,
                y: 0.3
            )
        )
        let url = client.imageURL(image)
            .width(30)
            .height(100)

        assert(url.URL()!.query == "rect=240,300,720,2400&w=30&h=100")
    }

    // TODO: Test overriding cdn hostname ala https://github.com/sanity-io/image-url/blob/f0a7b1430b64b2bb9ad9542a7b14e26bd905e3f5/test/fromClient.test.ts
}
