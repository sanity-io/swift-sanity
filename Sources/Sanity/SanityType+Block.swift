// MIT License
//
// Copyright (c) 2023 Sanity.io

import Foundation

public extension SanityType {
    struct Block {
        public let _key: String
        public let children: [Child]
        public let style: String
        public let markDefs: [MarkDef]

        public struct MarkDef {
            public let _key: String
            public let _type: String
            public let href: String?

            public init(_key: String, _type: String, href: String?) {
                self._key = _key
                self._type = _type
                self.href = href
            }
        }

        public struct Child {
            public enum Mark {
                case strong, em
                case markDef(String)
            }

            public let _key: String
            public let _type: String
            public let text: String
            public let marks: [Mark]

            public init(_key: String, _type: String, text: String, marks: [Mark]) {
                self._key = _key
                self._type = _type
                self.text = text
                self.marks = marks
            }
        }

        public init(_key: String, children: [Child], style: String, markDefs: [MarkDef]) {
            self._key = _key
            self.children = children
            self.style = style
            self.markDefs = markDefs
        }
    }
}

extension SanityType.Block: Decodable {
    enum CodingKeys: String, CodingKey {
        case _key, _type, children, markDefs, style
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: ._type)
        if type != "block" {
            throw SanityType.SanityDecodingError.invalidType(type: type)
        }

        self._key = try container.decode(String.self, forKey: ._key)
        self.children = try container.decode([Child].self, forKey: .children)
        self.markDefs = try container.decode([MarkDef].self, forKey: .markDefs)
        self.style = try container.decode(String.self, forKey: .style)
    }
}

extension SanityType.Block: Identifiable {
    public var id: String { self._key }
}

extension SanityType.Block: Equatable {
    public static func == (lhs: SanityType.Block, rhs: SanityType.Block) -> Bool {
        lhs.id == rhs.id
    }
}

extension SanityType.Block: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension SanityType.Block.Child: Decodable {
    enum CodingKeys: String, CodingKey {
        case _key, _type, marks, text
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self._key = try container.decode(String.self, forKey: ._key)
        self._type = try container.decode(String.self, forKey: ._type)
        self.marks = try container.decode([Mark].self, forKey: .marks)
        self.text = try container.decode(String.self, forKey: .text)
    }
}

extension SanityType.Block.Child: Identifiable {
    public var id: String { self._key }
}

extension SanityType.Block.Child: Equatable {
    public static func == (lhs: SanityType.Block.Child, rhs: SanityType.Block.Child) -> Bool {
        lhs.id == rhs.id
    }
}

extension SanityType.Block.Child: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension SanityType.Block.Child.Mark: Decodable {
    enum RawValues: String, Codable {
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

extension SanityType.Block.Child.Mark: Equatable, Hashable {}

extension SanityType.Block.MarkDef: Decodable {}

extension SanityType.Block.MarkDef: Identifiable {
    public var id: String { self._key }
}

extension SanityType.Block.MarkDef: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension SanityType.Block.MarkDef: Equatable {
    public static func == (lhs: SanityType.Block.MarkDef, rhs: SanityType.Block.MarkDef) -> Bool {
        lhs.id == rhs.id
    }
}
