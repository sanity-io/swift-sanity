// MIT License
//
// Copyright (c) 2021 Sanity.io

public extension SanityType {
    struct Ref {
        public let _ref: String
        public let _type: String

        init(_ref: String, _type: String) {
            self._ref = _ref
            self._type = _type
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
