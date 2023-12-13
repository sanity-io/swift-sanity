// MIT License
//
// Copyright (c) 2023 Sanity.io

public extension SanityType {
    struct Ref {
        public let _ref: String
        public let _type: String
        public let _weak: Bool?

        public init(_ref: String, _type: String, _weak: Bool? = nil) {
            self._ref = _ref
            self._type = _type
            self._weak = _weak
        }
    }
}

extension SanityType.Ref: Codable {}

extension SanityType.Ref: Hashable {}
extension SanityType.Ref: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._ref == rhs._ref && lhs._type == rhs._type
    }
}
