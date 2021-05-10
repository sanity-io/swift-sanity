// MIT License
//
// Copyright (c) 2021 Sanity.io

import Foundation

public extension SanityType {
    struct Slug {
        public let current: String

        public init(current: String) {
            self.current = current
        }
    }
}

extension SanityType.Slug: Decodable {
    enum CodingKeys: String, CodingKey {
        case _type, current
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: ._type)
        if type != "slug" {
            throw SanityType.SanityDecodingError.invalidType(type: type)
        }

        self.current = try container.decode(String.self, forKey: .current)
    }
}

extension SanityType.Slug: Hashable {}
extension SanityType.Slug: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.current == rhs.current
    }
}
