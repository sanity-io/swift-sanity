//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

struct SanityType {
    enum SanityDecodingError: Error {
        case invalidType(type: String)
        case invalidRef(ref: String)

        case invalidImageDimensions(dimensions: String)
    }
}

extension SanityType: Decodable {
    struct Ref: Decodable {
        let _ref: String
        let _type: String
    }
}
