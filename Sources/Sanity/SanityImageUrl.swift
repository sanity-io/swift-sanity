// MIT License
//
// Copyright (c) 2023 Sanity.io

import Foundation

public extension SanityClient {
    func imageURL(_ image: SanityType.Image) -> SanityImageUrl {
        SanityImageUrl(image, projectId: self.config.projectId, dataset: self.config.dataset)
    }
}

extension URL {
    init(sanityImageUrl: SanityImageUrl) {
        guard let url = sanityImageUrl.URL() else {
            preconditionFailure("Could not construct url from SanityImageUrl id: \(sanityImageUrl.image.id)")
        }

        self = url
    }
}

public struct SanityImageUrl {
    public let image: SanityType.Image
    private let projectId: String
    private let dataset: String

    public var width: Int?
    public var height: Int?
    public var maxWidth: Int?
    public var maxHeight: Int?
    public var minWidth: Int?
    public var minHeight: Int?
    public var blur: Int?
    public var sharpen: Int?
    public var dpr: Int?

    public var quality: Int?
    public var saturation: Int?
    public var pad: Double?

    public var invert: Bool?
    public var flipHorizontal: Bool?
    public var flipVertical: Bool?

    public var focalPoint: FocalPoint?
    public var auto: Auto?
    public var format: ImageFormat?
    public var orientation: Orientation?
    public var fit: Fit?
    public var crop: CropMode?

    private struct Rect {
        let left: Int
        let top: Int
        let width: Int
        let height: Int
    }

    public struct FocalPoint {
        let x: Int
        let y: Int
    }

    public enum Auto: String {
        case format
    }

    public enum ImageFormat: String {
        case jpg
        case pjpg
        case png
        case webp
    }

    public enum Fit: String {
        case clip
        case crop
        case fill
        case fillmax
        case max
        case scale
        case min
    }

    public enum Orientation: Int {
        case D0 = 0
        case D90 = 90
        case D180 = 180
        case D270 = 270
    }

    public enum CropMode: String {
        case top
        case bottom
        case left
        case right
        case center
        case focalpoint
        case entropy
    }

    init(_ image: SanityType.Image, projectId: String, dataset: String) {
        self.image = image
        self.projectId = projectId
        self.dataset = dataset
    }

    public func URL() -> URL? {
        if image.validImage == false {
            return nil
        }

        let filename = "\(image.id)-\(image.width)x\(image.height).\(image.format)"
        let baseUrl = "/images/\(self.projectId)/\(self.dataset)/\(filename)"

        var queryItems: [URLQueryItem] = []

        if let rect = self.calculateRect(), rect.left != 0 || rect.top != 0 || rect.height != image.height || rect.width != image.width {
            queryItems.append(.init(name: "rect", value: "\(rect.left),\(rect.top),\(rect.width),\(rect.height)"))
        }

        if let width = self.width {
            queryItems.append(.init(name: "w", value: "\(width)"))
        }

        if let height = self.height {
            queryItems.append(.init(name: "h", value: "\(height)"))
        }

        if let maxWidth = self.maxWidth {
            queryItems.append(.init(name: "max-w", value: "\(maxWidth)"))
        }

        if let maxHeight = self.maxHeight {
            queryItems.append(.init(name: "max-h", value: "\(maxHeight)"))
        }

        if let minWidth = self.minWidth {
            queryItems.append(.init(name: "min-w", value: "\(minWidth)"))
        }

        if let minHeight = self.minHeight {
            queryItems.append(.init(name: "min-h", value: "\(minHeight)"))
        }

        if let blur = self.blur {
            queryItems.append(.init(name: "blur", value: "\(blur)"))
        }

        if let sharpen = self.sharpen {
            queryItems.append(.init(name: "sharp", value: "\(sharpen)"))
        }

        if let dpr = self.dpr {
            queryItems.append(.init(name: "dpr", value: "\(dpr)"))
        }

        if let orientation = self.orientation {
            queryItems.append(.init(name: "or", value: "\(orientation.rawValue)"))
        }

        if let fit = self.fit {
            queryItems.append(.init(name: "fit", value: "\(fit)"))
        }

        if let flipHorizontal = self.flipHorizontal, let flipVertical = self.flipVertical, flipHorizontal, flipVertical {
            queryItems.append(.init(name: "flip", value: "hv"))
        } else if let flipHorizontal = self.flipHorizontal, flipHorizontal {
            queryItems.append(.init(name: "flip", value: "h"))
        } else if let flipVertical = self.flipVertical, flipVertical {
            queryItems.append(.init(name: "flip", value: "v"))
        }

        if let focalPoint = self.focalPoint {
            queryItems.append(.init(name: "fp-x", value: "\(focalPoint.x)"))
            queryItems.append(.init(name: "fp-y", value: "\(focalPoint.y)"))
        }

        if let invert = self.invert, invert == true {
            queryItems.append(.init(name: "invert", value: "true"))
        }

        if let format = self.format {
            queryItems.append(.init(name: "fm", value: "\(format.rawValue)"))
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

    private struct HotspotSpec {
        let left: Double
        let top: Double
        let right: Double
        let bottom: Double
    }

    private func calculateRect() -> Rect? {
        if image.validImage == false {
            return nil
        }

        guard let width = self.width, let height = self.height else {
            return nil
        }

        let cropSpec: Rect
        if let crop = image.crop {
            let cropLeft = crop.left * Double(image.width)
            let cropTop = crop.top * Double(image.height)
            cropSpec = Rect(
                left: Int(cropLeft),
                top: Int(cropTop),
                width: Int(Double(image.width) - crop.right * Double(image.width) - cropLeft),
                height: Int(Double(image.height) - crop.bottom * Double(image.height) - cropTop)
            )
        } else {
            cropSpec = Rect(
                left: 0,
                top: 0,
                width: image.width,
                height: image.height
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

        let desiredAspectRatio = Double(width) / Double(height)
        let cropAspectRatio = Double(cropSpec.width) / Double(cropSpec.height)

        let rect: Rect
        if cropAspectRatio > desiredAspectRatio {
            let height = Double(cropSpec.height)
            let width = height * desiredAspectRatio
            let top = Double(cropSpec.top)

            // Center output horizontally over hotspot
            let hotspotXCenter = (hotspotSpec.right - hotspotSpec.left) / 2 + hotspotSpec.left

            var left = hotspotXCenter - width / 2
            if left < Double(cropSpec.left) {
                left = Double(cropSpec.left)
            } else if (left + width) > Double(cropSpec.left + cropSpec.width) {
                left = Double(cropSpec.left + cropSpec.width) - width
            }

            rect = Rect(
                left: Int(round(left)),
                top: Int(round(top)),
                width: Int(round(width)),
                height: Int(round(height))
            )
        } else {
            // The crop is taller than the desired ratio, we are cutting from top and bottom
            let width = Double(cropSpec.width)
            let height = width / desiredAspectRatio
            let left = Double(cropSpec.left)

            let hotspotSpecTop = hotspotSpec.top

            // Center output vertically over hotspot
            let hotspotYCenter = (hotspotSpec.bottom - hotspotSpec.top) / 2 + hotspotSpecTop
            var top = hotspotYCenter - height / 2

            if top < Double(cropSpec.top) { // Keep output rect within crop
                top = Double(cropSpec.top)
            } else if top + height > Double(cropSpec.top + cropSpec.height) {
                top = Double(cropSpec.top + cropSpec.height) - height
            }

            rect = Rect(
                left: Int(round(max(0, floor(left)))),
                top: Int(round(max(0, floor(top)))),
                width: Int(round(width)),
                height: Int(round(height))
            )
        }

        return rect
    }

    public func width(_ width: Int?) -> Self {
        var imageUrl = self
        imageUrl.width = width
        return imageUrl
    }

    public func height(_ height: Int?) -> Self {
        var imageUrl = self
        imageUrl.height = height
        return imageUrl
    }

    public func maxWidth(_ maxWidth: Int?) -> Self {
        var imageUrl = self
        imageUrl.maxWidth = maxWidth
        return imageUrl
    }

    public func maxHeight(_ maxHeight: Int?) -> Self {
        var imageUrl = self
        imageUrl.maxHeight = maxHeight
        return imageUrl
    }

    public func minWidth(_ minWidth: Int?) -> Self {
        var imageUrl = self
        imageUrl.minWidth = minWidth
        return imageUrl
    }

    public func minHeight(_ minHeight: Int?) -> Self {
        var imageUrl = self
        imageUrl.minHeight = minHeight
        return imageUrl
    }

    public func blur(_ blur: Int?) -> Self {
        var imageUrl = self
        imageUrl.blur = blur
        return imageUrl
    }

    public func sharpen(_ sharpen: Int?) -> Self {
        var imageUrl = self
        imageUrl.sharpen = sharpen
        return imageUrl
    }

    public func quality(_ quality: Int?) -> Self {
        var imageUrl = self
        imageUrl.quality = quality
        return imageUrl
    }

    public func saturation(_ saturation: Int?) -> Self {
        var imageUrl = self
        imageUrl.saturation = saturation
        return imageUrl
    }

    public func dpr(_ dpr: Int?) -> Self {
        var imageUrl = self
        imageUrl.dpr = dpr
        return imageUrl
    }

    public func pad(_ pad: Double?) -> Self {
        var imageUrl = self
        imageUrl.pad = pad
        return imageUrl
    }

    public func invert(_ invert: Bool?) -> Self {
        var imageUrl = self
        imageUrl.invert = invert
        return imageUrl
    }

    public func flipHorizontal(_ flipHorizontal: Bool?) -> Self {
        var imageUrl = self
        imageUrl.flipHorizontal = flipHorizontal
        return imageUrl
    }

    public func flipVertical(_ flipVertical: Bool?) -> Self {
        var imageUrl = self
        imageUrl.flipVertical = flipVertical
        return imageUrl
    }

    public func focalPoint(_ focalPoint: FocalPoint?) -> Self {
        var imageUrl = self
        imageUrl.focalPoint = focalPoint
        return imageUrl
    }

    public func auto(_ auto: Auto?) -> Self {
        var imageUrl = self
        imageUrl.auto = auto
        return imageUrl
    }

    public func format(_ format: ImageFormat?) -> Self {
        var imageUrl = self
        imageUrl.format = format
        return imageUrl
    }

    public func orientation(_ orientation: Orientation?) -> Self {
        var imageUrl = self
        imageUrl.orientation = orientation
        return imageUrl
    }

    public func fit(_ fit: Fit?) -> Self {
        var imageUrl = self
        imageUrl.fit = fit
        return imageUrl
    }

    public func crop(_ crop: CropMode?) -> Self {
        var imageUrl = self
        imageUrl.crop = crop
        return imageUrl
    }
}
