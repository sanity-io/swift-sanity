// MIT License
//
// Copyright (c) 2021 Sanity.io

public struct SanityType {
    public enum SanityDecodingError: Error {
        case invalidType(type: String)
        case invalidRef(ref: String)

        case invalidImageDimensions(dimensions: String)
    }
}
