// MIT License
//
// Copyright (c) 2023 Sanity.io

import Foundation

// Based on https://github.com/sanity-io/client/blob/31ecabdc523b4543083ee03300c18557528d6961/src/data/dataMethods.js#L37
let kQuerySizeLimitPost = 11264

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
        public let perspective: Perspective?
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
            case v20250219

            case latest
            case custom(String)

            var string: String {
                switch self {
                case .v1:
                    return "v1"
                case .v20210325:
                    return "v2021-03-25"
                case .v20250219:
                    return "v2025-02-19"
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

        func getURLRequest(path: String = "/", queryItems: [URLQueryItem]? = nil) -> URLRequest {
            let url = getURL(path: path, queryItems: queryItems)
            var request = URLRequest(url: url)

            request.addValue("sanity-swift/1.0", forHTTPHeaderField: "User-Agent")
            if let token = self.token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            return request
        }

        func getURLRequest(path: String = "/", body: Data?, queryItems: [URLQueryItem]? = nil) -> URLRequest {
            var request = getURLRequest(path: path, queryItems: queryItems)
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "content-type")

            return request
        }

        func getURLRequest(path: String = "/", queryItems: [URLQueryItem]? = nil, canUsePost: Bool = false) -> URLRequest {
            let url = getURL(path: path, queryItems: queryItems)
            if let queryItems, canUsePost, url.absoluteString.count > kQuerySizeLimitPost {
                let bodyItemNames = ["query"]

                var bodyObject: [String: String] = [:]
                var remainigQueryItems: [URLQueryItem] = []
                for queryItem in queryItems {
                    if bodyItemNames.contains(queryItem.name) {
                        bodyObject[queryItem.name] = queryItem.value
                    } else {
                        remainigQueryItems.append(queryItem)
                    }
                }

                let body = try? JSONSerialization.data(withJSONObject: bodyObject)
                return getURLRequest(path: path, body: body, queryItems: remainigQueryItems.isEmpty ? nil : remainigQueryItems)
            }

            return getURLRequest(path: path, queryItems: queryItems)
        }

        public init(projectId: String, dataset: String, version: APIVersion, perspective: Perspective?, useCdn: Bool, token: String?) {
            self.projectId = projectId
            self.dataset = dataset
            self.version = version
            self.perspective = perspective
            self.token = token
            self.useCdn = useCdn
        }
    }

    public struct Query<T> {
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
                    var items = [URLQueryItem(name: "query", value: query)]
                    if let perspective = config.perspective {
                        items.append(URLQueryItem(name: "perspective", value: perspective.rawValue))
                    }
                    addParams(params, to: &items)

                    let path = "/data/query/\(config.dataset)"
                    return config.getURLRequest(path: path, queryItems: items, canUsePost: true)

                case let .listen(query, params, config, includeResult, includePreviousRevision, visibility):
                    var items = [URLQueryItem(name: "query", value: query)]
                    if let includeResult {
                        items.append(URLQueryItem(name: "includeResult", value: "\(includeResult)"))
                    }
                    if let includePreviousRevision {
                        items.append(URLQueryItem(name: "includePreviousRevision", value: "\(includePreviousRevision)"))
                    }
                    if let visibility {
                        items.append(URLQueryItem(name: "visibility", value: "\(visibility)"))
                    }
                    addParams(params, to: &items)

                    let path = "/data/listen/\(config.dataset)"
                    return config.getURLRequest(path: path, queryItems: items)
                }
            }

            private func addParams(_ params: [String: Any], to queryItems: inout [URLQueryItem]) {
                params
                    .sorted { $0.key < $1.key }
                    .forEach { param in
                        let queryItem = URLQueryItem(name: "$\(param.key)", value: String(describing: param.value))
                        queryItems.append(queryItem)
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

    public struct Transaction {
        public let config: Config
        public var mutations: [Mutation] = []
        public let urlSession: URLSession

        func encode(_ options: JSONSerialization.WritingOptions = [.sortedKeys]) throws -> Data {
            let jsonObject: [String: Any] = [
                "mutations": mutations.compactMap { $0.encode() }.flatMap { $0 },
            ]

            return try JSONSerialization.data(withJSONObject: jsonObject, options: options)
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
    /// - Parameter perspective: The perspective to use, see https://www.sanity.io/docs/content-lake/perspectives
    /// - Parameter useCdn: Whether or not to run query against the API CDN, see https://www.sanity.io/docs/api-cdn
    /// - Parameter token: Depending on your dataset configuration you might need an API token to query, see https://www.sanity.io/docs/keeping-your-data-safe
    ///
    /// - Warning: We encourage most users to use the api cdn for their front-ends unless there is a good reason not to.
    ///
    /// - Returns: SanityClient
    public init(projectId: String, dataset: String, version: Config.APIVersion = .v20210325, perspective: Perspective? = nil, useCdn: Bool, token: String? = nil) {
        self.config = Config(projectId: projectId, dataset: dataset, version: version, perspective: perspective, useCdn: useCdn, token: token)
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

    /// Constructs a groq query which returns a Data response
    ///
    /// - Parameter query: GROQ query
    /// - Parameter params: A dictionary of parameters
    ///
    /// - Returns: Query<Void>
    public func query(query: String, params: [String: Any] = [:]) -> Query<Void> {
        Query<Void>(config: config, query: query, params: params, urlSession: urlSession)
    }
}
