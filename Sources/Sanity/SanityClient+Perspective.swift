// MIT License
//
// Copyright (c) 2023 Sanity.io

extension SanityClient {
    public struct Perspective: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension SanityClient.Perspective: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

extension SanityClient.Perspective {
    public static let raw = Self(rawValue: "raw")
    public static let drafts = Self(rawValue: "drafts")
    public static let published = Self(rawValue: "published")
}

extension SanityClient.Perspective {
    public static func layers(_ layers: Self...) -> Self {
        return Self(rawValue: layers
            .map(\.rawValue)
            .joined(separator: ","))
    }
}
