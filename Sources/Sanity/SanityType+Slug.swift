// MIT License
//
// Copyright (c) 2021 Sanity.io

import Foundation

public extension SanityType {
    struct Slug: Decodable {
        let current: String

        enum CodingKeys: String, CodingKey {
            case _type, current
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: ._type)
            if type != "slug" {
                throw SanityDecodingError.invalidType(type: type)
            }

            self.current = try container.decode(String.self, forKey: .current)
        }
    }
}
