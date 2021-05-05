//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

public struct SanityType {
    public enum SanityDecodingError: Error {
        case invalidType(type: String)
        case invalidRef(ref: String)

        case invalidImageDimensions(dimensions: String)
    }
}

extension SanityType: Decodable {
    public struct Ref: Decodable {
        let _ref: String
        let _type: String
    }
}
