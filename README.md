# Swift Sanity

Code for interacting with Sanity content from Swift on iOS and macOS. This package is under development and may long term aim for feature parity with the [JavaScript client](https://www.sanity.io/docs/js-client), but for the time being is limited to Sanity asset pipeline URL generation.

## Generate image asset URLs

This module provides `SanityType.Image` which when put through `imageURL` on `SanityClient` will generate image asset URLs which respect any hotspot or crop rect set by editors.

```swift
let client = SanityClient(projectId: "zp7mbokg", dataset: "production")
let image = SanityType.Image(
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
let url = client.imageURL(image, width: 30, height: 100)
// => "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?rect=240,300,720,2400&w=30&h=100"

```
Note that a SanityClient is used here but this operation will not result in a network call. The `projectId` and `dataset` name is needed to generate asset URL.
