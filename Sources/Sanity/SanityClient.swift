// MIT License
//
// Copyright (c) 2021 Sanity.io

import Foundation
import GenericJSON

public class SanityClient {
    let urlSession = URLSession(configuration: .default)

    public let config: Config

    public enum ClientError: Error {
        case server(url: URL, code: Int)
        case missingData
    }

    public struct Config {
        public let projectId: String
        public let dataset: String
        public let version: APIVersion
        public let token: String?
        public let useCdn: Bool
        public var apiHost: APIHost {
            // TODO: There are a few more conditions that will exclude CDN as a valid host, such as:
            // config with custom apihost domain
            // Any request that isnt GET or HEAD
            // Query Listening?
            if useCdn == true, token == nil {
                return .productionCDN
            }

            return .production
        }

        public enum APIHost {
            case production
            case productionCDN
            case custom(String)

            var host: String {
                switch self {
                case .production:
                    return "api.sanity.io"
                case .productionCDN:
                    return "apicdn.sanity.io"
                case let .custom(string):
                    return string
                }
            }

            func hostForProjectId(_ projectId: String) -> String {
                "\(projectId).\(self.host)"
            }
        }

        public enum APIVersion {
            case v1
            case v20210325

            case latest
            case custom(String)

            var string: String {
                switch self {
                case .v1:
                    return "v1"
                case .v20210325:
                    return "v2021-03-25"
                case .latest:
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"

                    return "v\(formatter.string(from: Date()))"
                case let .custom(string):
                    return string
                }
            }
        }

        func getURL(path: String = "/", queryItems: [URLQueryItem]? = nil) -> URL {
            var components = URLComponents()
            components.scheme = "https"
            components.host = self.apiHost.hostForProjectId(self.projectId)
            components.path = "/" + self.version.string + path
            components.queryItems = queryItems
            return components.url!
        }

        internal func getURLRequest(path: String = "/", queryItems: [URLQueryItem]? = nil) -> URLRequest {
            let url = getURL(path: path, queryItems: queryItems)
            var request = URLRequest(url: url)

            if let token = self.token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            return request
        }

        public init(projectId: String, dataset: String, version: APIVersion, useCdn: Bool, token: String?) {
            self.projectId = projectId
            self.dataset = dataset
            self.version = version
            self.token = token
            self.useCdn = useCdn
        }
    }

    public struct Query<T: Decodable> {
        public let config: Config
        public let query: String
        public let params: [String: Any]
        public let urlSession: URLSession

        enum apiURL {
            case fetch(query: String, params: [String: Any], config: Config)
            case listen(query: String, params: [String: Any], config: Config, includeResult: Bool?, includePreviousRevision: Bool?, visibility: String?)

            var urlRequest: URLRequest {
                switch self {
                case let .fetch(query, params, config):
                    let items = queryItems(defaults: [
                        "query": query,
                    ], params: params)

                    let path = "/data/query/\(config.dataset)"
                    return config.getURLRequest(path: path, queryItems: items)

                case let .listen(query, params, config, includeResult, includePreviousRevision, visibility):
                    var defaults = [ "query": query ]
                    if let includeResult = includeResult {
                        defaults["includeResult"] = "\(includeResult)"
                    }

                    if let includePreviousRevision = includePreviousRevision {
                        defaults["includePreviousRevision"] = "\(includePreviousRevision)"
                    }

                    if let visibility = visibility {
                        defaults["visibility"] = "\(visibility)"
                    }

                    let items = queryItems(defaults: defaults, params: params)

                    let path = "/data/listen/\(config.dataset)"
                    return config.getURLRequest(path: path, queryItems: items)
                }
            }

            private func queryItems(defaults: [String: Any], params: [String: Any]) -> [URLQueryItem] {
                let prefixedParams = params.reduce(into: [:]) { result, x in
                    result["$\(x.key)"] = x.value
                }
                let mergedParams: [String: Any] = defaults.merging(prefixedParams) { _, new in new }

                return mergedParams.map { key, value in
                    URLQueryItem(name: key, value: String(describing: value))
                }
            }

            private func getURLForPaths(_ paths: [String], queryItems: [URLQueryItem], config: Config) -> URL {
                let url = config.getURL(path: "/" + paths.joined(separator: "/"))
                var components = URLComponents(string: url.absoluteString)!
                components.queryItems = queryItems
                return components.url!
            }

            private func parseParams(_ params: [String: Any]) -> [URLQueryItem] {
                params.map { key, value in
                    URLQueryItem(name: key, value: String(describing: value))
                }
            }
        }
    }

    /// Initalizes the Sanity Client
    ///
    /// - Parameter config: The SanityClient.Config object
    ///
    /// - Returns: SanityClient
    public init(config: Config) {
        self.config = config
    }

    /// Initalizes the Sanity Client
    ///
    /// - Parameter projectId: The project id to use
    /// - Parameter dataset: The dataset to use, see https://www.sanity.io/docs/datasets
    /// - Parameter version: The API version to use, see https://www.sanity.io/docs/api-versioning
    /// - Parameter useCdn: Whether or not to run query against the API CDN, see https://www.sanity.io/docs/api-cdn
    /// - Parameter token: Depending on your dataset configuration you might need an API token to query, see https://www.sanity.io/docs/keeping-your-data-safe
    ///
    /// - Warning: We encourage most users to use the api cdn for their front-ends unless there is a good reason not to.
    ///
    /// - Returns: SanityClient
    public init(projectId: String, dataset: String, version: Config.APIVersion = .v20210325, useCdn: Bool, token: String? = nil) {
        self.config = Config(projectId: projectId, dataset: dataset, version: version, useCdn: useCdn, token: token)
    }

    /// Constructs a groq query of type T
    ///
    /// - Parameter _: Type of returned data
    /// - Parameter query: GROQ query
    /// - Parameter params: A dictionary of parameters
    ///
    /// - Returns: Query<T>
    public func query<T: Decodable>(_: T.Type, query: String, params: [String: Any] = [:]) -> Query<T> {
        Query<T>(config: config, query: query, params: params, urlSession: urlSession)
    }

    /// Constructs a groq query which returns a GenericJSON type, see https://github.com/zoul/generic-json-swift
    ///
    /// - Parameter query: GROQ query
    /// - Parameter params: A dictionary of parameters
    ///
    /// - Returns: Query<JSON>
    public func query(query: String, params: [String: Any] = [:]) -> Query<JSON> {
        Query<JSON>(config: config, query: query, params: params, urlSession: urlSession)
    }
}
