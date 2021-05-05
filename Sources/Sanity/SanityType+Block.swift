//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

import Foundation

public extension SanityType {
    struct Block: Decodable, Identifiable {
        public var id: String { self._key }

        public let _key: String
        public let children: [Child]
        public let style: String
        public let markDefs: [MarkDef]

        enum CodingKeys: String, CodingKey {
            case _key, _type, children, markDefs, style
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: ._type)
            if type != "block" {
                throw SanityDecodingError.invalidType(type: type)
            }

            self._key = try container.decode(String.self, forKey: ._key)
            self.children = try container.decode([Child].self, forKey: .children)
            self.markDefs = try container.decode([MarkDef].self, forKey: .markDefs)
            self.style = try container.decode(String.self, forKey: .style)
        }

        public enum Style: String, Decodable {
            case normal, h1, h2, h3, h4, h5, h6, blockquote
        }

        public struct MarkDef: Decodable {
            public let _key: String
            public let _type: String
            public let href: String?
        }

        public struct Child: Decodable, Identifiable {
            public enum Mark: Decodable, Equatable {
                case strong, em

                case markDef(String)

                fileprivate enum RawValues: String, Codable {
                    case strong
                    case em
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    // As you already know your RawValues is String actually, you decode String here
                    let stringForRawValues = try container.decode(String.self)
                    // This is the trick here...
                    switch stringForRawValues {
                    // Now You can switch over this String with cases from RawValues since it is String
                    case RawValues.strong.rawValue:
                        self = .strong
                    case RawValues.em.rawValue:
                        self = .em

                    default:
                        self = .markDef(stringForRawValues)
                    }
                }
            }

            public var id: String { self._key }

            public let _key: String
            public let _type: String
            public let text: String
            public let marks: [Mark]
        }
    }
}
