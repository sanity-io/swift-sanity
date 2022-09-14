// MIT License
//
// Copyright (c) 2021 Sanity.io

import Foundation

public extension SanityType {
    struct Image {
        public let id: String
        public let width: Int
        public let height: Int
        public let format: String

        public let asset: Ref
        public let crop: Crop?
        public let hotspot: Hotspot?

        public let validImage: Bool

        public struct Crop {
            public let bottom: Double
            public let left: Double
            public let top: Double
            public let right: Double

            public init(bottom: Double, left: Double, top: Double, right: Double) {
                self.bottom = bottom
                self.left = left
                self.top = top
                self.right = right
            }
        }

        public struct Hotspot {
            public let width: Double
            public let height: Double
            public let x: Double
            public let y: Double

            public init(width: Double, height: Double, x: Double, y: Double) {
                self.width = width
                self.height = height
                self.x = x
                self.y = y
            }
        }

        public init(asset: Ref, crop: Crop?, hotspot: Hotspot?) {
            self.asset = asset
            self.crop = crop
            self.hotspot = hotspot

            let assetRefParts = self.asset._ref.split(separator: Character("-"))
            let dimensions = assetRefParts[safe: 2]?.split(separator: Character("x"))

            guard let id = assetRefParts[safe: 1],
                  let format = assetRefParts[safe: 3],
                  let width = dimensions?[safe: 0],
                  let height = dimensions?[safe: 1]
            else {
                self.id = "-"
                self.format = "-"
                self.width = 0
                self.height = 0
                self.validImage = false
                return
            }

            self.id = String(id)
            self.format = String(format)
            self.width = Int(width) ?? 0
            self.height = Int(height) ?? 0
            self.validImage = true
        }

        public init(id: String, width: Int, height: Int, format: String, validImage: Bool, crop: Crop?, hotspot: Hotspot?) {
            self.id = id
            self.width = width
            self.height = height
            self.format = format
            self.validImage = validImage

            self.asset = Ref(_ref: "image-\(id)-\(width)x\(height)-\(format)", _type: "image")
            self.crop = crop
            self.hotspot = hotspot
        }
    }
}

extension SanityType.Image: Codable {
    enum CodingKeys: String, CodingKey {
        case _type, asset, crop, hotspot
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: ._type)
        if type != "image" {
            throw SanityType.SanityDecodingError.invalidType(type: type)
        }

        let asset = try container.decode(SanityType.Ref.self, forKey: .asset)
        let crop = try? container.decode(Crop.self, forKey: .crop)
        let hotspot = try? container.decode(Hotspot.self, forKey: .hotspot)

        self.init(asset: asset, crop: crop, hotspot: hotspot)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("image", forKey: ._type)

        try container.encode(asset, forKey: .asset)
        try container.encode(crop, forKey: .crop)
        try container.encode(hotspot, forKey: .hotspot)
    }
}

extension SanityType.Image.Crop: Codable {}
extension SanityType.Image.Hotspot: Codable {}

extension SanityType.Image.Crop: Hashable, Equatable {}
extension SanityType.Image.Hotspot: Hashable, Equatable {}
extension SanityType.Image: Hashable, Equatable {}

fileprivate extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
