//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

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

public class SanityImageUrl {
    public let image: SanityType.Image
    private let projectId: String
    private let dataset: String

    private var width: Int?
    private var height: Int?
    private var maxWidth: Int?
    private var maxHeight: Int?
    private var minWidth: Int?
    private var minHeight: Int?
    private var blur: Int?
    private var sharpen: Int?
    private var dpr: Int?

    private var quality: Int?
    private var saturation: Int?
    private var pad: Double?

    private var invert: Bool?
    private var flipHorizontal: Bool?
    private var flipVertical: Bool?

    private var rect: Rect?
    private var focalPoint: FocalPoint?
    private var auto: Auto?
    private var format: ImageFormat?
    private var orientation: Orientation?
    private var fit: Fit?
    private var crop: CropMode?

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

    func URL() -> URL? {
        if image.validImage == false {
            return nil
        }

        let filename = "\(image.id)-\(image.width)x\(image.height).\(image.format)"
        let baseUrl = "/images/\(self.projectId)/\(self.dataset)/\(filename)"

        var queryItems: [URLQueryItem] = []

        self.calculateRect()

        if let rect = self.rect, rect.left != 0 || rect.top != 0 || rect.height != image.height || rect.width != image.width {
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

    private func calculateRect() {
        if image.validImage == false {
            return
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

        guard let width = self.width, let height = self.height else {
            return
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

        self.rect = rect
        self.width = width
        self.height = height
    }

    public func width(_ width: Int?) -> Self {
        self.width = width
        return self
    }

    public func height(_ height: Int?) -> Self {
        self.height = height
        return self
    }

    public func maxWidth(_ maxWidth: Int?) -> Self {
        self.maxWidth = maxWidth
        return self
    }

    public func maxHeight(_ maxHeight: Int?) -> Self {
        self.maxHeight = maxHeight
        return self
    }

    public func minWidth(_ minWidth: Int?) -> Self {
        self.minWidth = minWidth
        return self
    }

    public func minHeight(_ minHeight: Int?) -> Self {
        self.minHeight = minHeight
        return self
    }

    public func blur(_ blur: Int?) -> Self {
        self.blur = blur
        return self
    }

    public func sharpen(_ sharpen: Int?) -> Self {
        self.sharpen = sharpen
        return self
    }

    public func quality(_ quality: Int?) -> Self {
        self.quality = quality
        return self
    }

    public func saturation(_ saturation: Int?) -> Self {
        self.saturation = saturation
        return self
    }

    public func dpr(_ dpr: Int?) -> Self {
        self.dpr = dpr
        return self
    }

    public func pad(_ pad: Double?) -> Self {
        self.pad = pad
        return self
    }

    public func invert(_ invert: Bool?) -> Self {
        self.invert = invert
        return self
    }

    public func flipHorizontal(_ flipHorizontal: Bool?) -> Self {
        self.flipHorizontal = flipHorizontal
        return self
    }

    public func flipVertical(_ flipVertical: Bool?) -> Self {
        self.flipVertical = flipVertical
        return self
    }

    public func focalPoint(_ focalPoint: FocalPoint?) -> Self {
        self.focalPoint = focalPoint

        return self
    }

    public func auto(_ auto: Auto?) -> Self {
        self.auto = auto

        return self
    }

    public func format(_ format: ImageFormat?) -> Self {
        self.format = format

        return self
    }

    public func orientation(_ orientation: Orientation?) -> Self {
        self.orientation = orientation

        return self
    }

    public func fit(_ fit: Fit?) -> Self {
        self.fit = fit

        return self
    }

    public func crop(_ crop: CropMode?) -> Self {
        self.crop = crop

        return self
    }
}
