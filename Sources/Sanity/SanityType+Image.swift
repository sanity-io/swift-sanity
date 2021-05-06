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
            let bottom: Double
            let left: Double
            let right: Double
            let top: Double
        }

        public struct Hotspot {
            let height: Double
            let width: Double
            let x: Double
            let y: Double
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
    }
}

fileprivate extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension SanityType.Image: Decodable {
    enum CodingKeys: String, CodingKey {
        case _type, asset, crop, hotspot
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let asset = try container.decode(SanityType.Ref.self, forKey: .asset)
        let crop = try? container.decode(Crop.self, forKey: .crop)
        let hotspot = try? container.decode(Hotspot.self, forKey: .hotspot)

        self.init(asset: asset, crop: crop, hotspot: hotspot)
    }
}

extension SanityType.Image.Crop: Decodable {}
extension SanityType.Image.Hotspot: Decodable {}
