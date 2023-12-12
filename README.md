# Swift Sanity

Code for interacting with Sanity content from Swift on iOS and macOS. This package is under development and may long term aim for feature parity with the [JavaScript client](https://www.sanity.io/docs/js-client), but for the time being is limited to groq queries, realtime listening and image asset url generation.

## Queries

You can perform queries with typed results, or untyped.

### Typed results

Simply pass in a type to the query function.

```swift
import Foundation
import Sanity

let client = SanityClient(projectId: "3do82whm", dataset: "next")

// Our result type
struct Post: Decodable {
    let title: String
    let slug: String?
    let poster: SanityType.Image
}

var groq = """
* [_type == "post"] {
  title,
  "slug": slug.current,
  poster
}[0...1]
"""

let query = client.query([Post].self, query: groq)

query.fetch { completion in
    /// Receive and update values on the main queue
    DispatchQueue.main.async {
        switch(completion) {
        case .success(let response):
            dump(response.result)
        case .failure(let error):
            dump(error)
        }
    }
}
```

outputs
```
1 element
  ▿ QueryTester.Post
    - title: "Introducing Glush: a robust, human readable, top-down parser compiler"
    ▿ slug: Optional("why-we-wrote-yet-another-parser-compiler")
      - some: "why-we-wrote-yet-another-parser-compiler"
    ▿ poster: Sanity.SanityType.Image
      - id: "18b2c50584718e1356e696ab22a3499e4ba65b55"
      - width: 5760
      - height: 3840
      - format: "png"
      ▿ asset: Sanity.SanityType.Ref
        - _ref: "image-18b2c50584718e1356e696ab22a3499e4ba65b55-5760x3840-png"
        - _type: "reference"
      - crop: nil
      - hotspot: nil
      - validImage: true
```

### Untyped results

Omitting the type will return a success type with Data. All status codes less than 300 will return a success value.
See https://www.sanity.io/docs/http-query for information about the response object

```swift
// ...
let query = client.query(query: groq)

query.fetch { completion in
    switch(completion) {
    case .success(let data):
        let jsonString = String(data: data, encoding: .utf8)
        print(data)
    case .failure(let error):
        dump(error)
    }
}
```

## Query Listening

See the [example app](Example/SanityDemoApp/SanityDemoApp/ContentView.swift) for an example of listening to queries. This will push new results to you as content changes server side.

[Sanity.io documentation on realtime updates](https://www.sanity.io/docs/realtime-updates)

## Mutations

*Note: To send mutation the client needs to be initalized with a token*

### With completion handler:

```swift
client.mutate([
    .patch(documentId: "some-id", patches: [
        Patch("counter", operation: .setIfMissing(0)),
        Patch("counter", operation: .inc(1)),
    ]),
]) { result in 
    switch result {
    case let .failure(error):
        self.error = error
    case .success:
        break
    }
}

```

### async/await:

Mutate also has swift async support:

```swift
let result = await SanityDemoApp.sanityClient.mutate([
    .patch(documentId: movie._id, patches: [
        Patch("counter", operation: .setIfMissing(0)),
        Patch("counter", operation: .inc(1)),
    ]),
])
switch result {
case let .failure(error):
    self.error = error
case .success:
    break
}
```

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
    .URL()

// => "https://cdn.sanity.io/images/zp7mbokg/production/Tb9Ew8CXIwaY6R1kjMvI0uRR-2000x3000.jpg?rect=240,300,720,2400&w=30&h=100"

```
Note that a SanityClient is used here but this operation will not result in a network call. The `projectId` and `dataset` name is needed to generate asset URL.
