//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

import Foundation

extension SanityType {
    struct Block: Decodable, Identifiable {
        var id: String { self._key }

        let _key: String
        let children: [Child]
        let style: String
        let markDefs: [MarkDef]

        enum CodingKeys: String, CodingKey {
            case _key, _type, children, markDefs, style
        }

        init(from decoder: Decoder) throws {
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

        enum Style: String, Decodable {
            case normal, h1, h2, h3, h4, h5, h6, blockquote
        }

        struct MarkDef: Decodable {
            let _key: String
            let _type: String
            let href: String?
        }

        struct Child: Decodable, Identifiable {
            enum Mark: Decodable, Equatable {
                case strong, em

                case markDef(String)

                private enum RawValues: String, Codable {
                    case strong
                    case em
                }

                init(from decoder: Decoder) throws {
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

            var id: String { self._key }

            let _key: String
            let _type: String
            let text: String
            let marks: [Mark]
        }
    }
}
