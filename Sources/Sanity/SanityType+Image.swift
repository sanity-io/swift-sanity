//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

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
        let type = try container.decode(String.self, forKey: ._type)
        if type != "image" {
            throw SanityType.SanityDecodingError.invalidType(type: type)
        }

        let asset = try container.decode(SanityType.Ref.self, forKey: .asset)
        let crop = try? container.decode(Crop.self, forKey: .crop)
        let hotspot = try? container.decode(Hotspot.self, forKey: .hotspot)

        self.init(asset: asset, crop: crop, hotspot: hotspot)
    }
}

extension SanityType.Image.Crop: Decodable {}
extension SanityType.Image.Hotspot: Decodable {}

extension SanityClient {
    public func imageURL(_ image: SanityType.Image, width: Double? = nil, height: Double? = nil) -> URL? {
        if image.validImage == false {
            return nil
        }

        let filename = "\(image.id)-\(image.width)x\(image.height).\(image.format)"
        let baseUrl = "/images/\(self.config.projectId)/\(self.config.dataset)/\(filename)"

        var queryItems: [URLQueryItem] = []

        let cropSpec: CropSpec
        if let crop = image.crop {
            cropSpec = CropSpec(
                left: crop.left * Double(image.width),
                top: crop.top * Double(image.height),
                width: Double(image.width) - crop.right * Double(image.width) - (crop.left * Double(image.width)),
                height: Double(image.height) - crop.bottom * Double(image.height) - (crop.top * Double(image.height))
            )
        } else {
            cropSpec = CropSpec(
                left: 0,
                top: 0,
                width: Double(image.width),
                height: Double(image.height)
            )
        }

        let hotspotSpec: HotspotSpec
        if let hotspot = image.hotspot {
            let hotSpotVerticalRadius = (hotspot.height * Double(image.height)) / 2
            let hotSpotHorizontalRadius = (hotspot.width * Double(image.width)) / 2
            let hotSpotCenterX = hotspot.x * Double(image.width)
            let hotSpotCenterY = hotspot.y * Double(image.height)

            hotspotSpec = HotspotSpec(
                left: hotSpotCenterX - hotSpotHorizontalRadius,
                top: hotSpotCenterY - hotSpotVerticalRadius,
                right: hotSpotCenterX + hotSpotHorizontalRadius,
                bottom: hotSpotCenterY + hotSpotVerticalRadius
            )
        } else {
            let hotSpotVerticalRadius = (1.0 * Double(image.height)) / 2
            let hotSpotHorizontalRadius = (1.0 * Double(image.width)) / 2
            let hotSpotCenterX = 0.5 * Double(image.width)
            let hotSpotCenterY = 0.5 * Double(image.height)

            hotspotSpec = HotspotSpec(
                left: hotSpotCenterX - hotSpotHorizontalRadius,
                top: hotSpotCenterY - hotSpotVerticalRadius,
                right: hotSpotCenterX + hotSpotHorizontalRadius,
                bottom: hotSpotCenterY + hotSpotVerticalRadius
            )
        }

        let fitResult = self.fit(image, cropSpec: cropSpec, hotspotSpec: hotspotSpec, width: width, height: height)

        let rect = fitResult.rect
        if rect.left != 0 || rect.top != 0 || rect.height != Double(image.height) || rect.width != Double(image.width) {
            queryItems.append(.init(name: "rect", value: "\(Int(rect.left)),\(Int(rect.top)),\(Int(rect.width)),\(Int(rect.height))"))
        }

        if let width = width {
            queryItems.append(.init(name: "w", value: "\(Int(width))"))
        }

        if let height = height {
            queryItems.append(.init(name: "h", value: "\(Int(height))"))
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "cdn.sanity.io"
        components.path = baseUrl
        if queryItems.count > 0 {
            components.queryItems = queryItems
        }

        return components.url
    }

    private struct CropSpec {
        let left: Double
        let top: Double
        let width: Double
        let height: Double
    }

    private struct HotspotSpec {
        let left: Double
        let top: Double
        let right: Double
        let bottom: Double
    }

    private struct FitResult {
        let width: Double?
        let height: Double?
        let rect: CropSpec
    }

    private func fit(_: SanityType.Image, cropSpec: CropSpec, hotspotSpec: HotspotSpec, width: Double? = nil, height: Double? = nil) -> FitResult {
        guard let width = width, let height = height else {
            return FitResult(width: width, height: height, rect: cropSpec)
        }

        let desiredAspectRatio = width / height
        let cropAspectRatio = cropSpec.width / cropSpec.height

        var rect: CropSpec
        if cropAspectRatio > desiredAspectRatio {
            let height = cropSpec.height
            let width = height * desiredAspectRatio
            let top = cropSpec.top

            // Center output horizontally over hotspot
            let hotspotXCenter = (hotspotSpec.right - hotspotSpec.left) / 2 + hotspotSpec.left

            var left = hotspotXCenter - width / 2
            if left < cropSpec.left {
                left = cropSpec.left
            } else if (left + width) > (cropSpec.left + cropSpec.width) {
                left = cropSpec.left + cropSpec.width - width
            }

            rect = CropSpec(
                left: round(left),
                top: round(top),
                width: round(width),
                height: round(height)
            )
        } else {
            // The crop is taller than the desired ratio, we are cutting from top and bottom
            let width = cropSpec.width
            let height = width / desiredAspectRatio
            let left = cropSpec.left

            let hotspotSpecTop = hotspotSpec.top

            // Center output vertically over hotspot
            let hotspotYCenter = (hotspotSpec.bottom - hotspotSpec.top) / 2 + hotspotSpecTop
            var top = hotspotYCenter - height / 2

            if top < cropSpec.top { // Keep output rect within crop
                top = cropSpec.top
            } else if top + height > (cropSpec.top + cropSpec.height) {
                top = cropSpec.top + cropSpec.height - height
            }

            rect = CropSpec(
                left: round(max(0, floor(left))),
                top: round(max(0, floor(top))),
                width: round(width),
                height: round(height)
            )
        }

        return FitResult(width: width, height: height, rect: rect)
    }
}
