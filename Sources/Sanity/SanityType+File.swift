// MIT License
//
// Copyright (c) 2021 Sanity.io

import Foundation

public extension SanityType {
    struct File {
        public let asset: Ref

        public init(asset: Ref) {
            self.asset = asset
        }
    }
}

public extension SanityClient {
    func fileURL(_ file: SanityType.File) -> URL? {
        let id = file.asset._ref

        let comp = id.components(separatedBy: "-")
        if comp.count != 3 {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "cdn.sanity.io"
        components.path = "/files/\(self.config.projectId)/\(self.config.dataset)/\(comp[1]).\(comp[2])"

        return components.url
    }
}

extension SanityType.File: Decodable {
    enum CodingKeys: String, CodingKey {
        case _type, asset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: ._type)
        if type != "file" {
            throw SanityType.SanityDecodingError.invalidType(type: type)
        }

        let asset = try container.decode(SanityType.Ref.self, forKey: .asset)

        self.init(asset: asset)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("file", forKey: ._type)

        try container.encode(asset, forKey: .asset)
    }
}
