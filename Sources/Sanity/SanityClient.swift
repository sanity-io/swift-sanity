// MIT License
//
// Copyright (c) 2021 Sanity.io

import Foundation
import GenericJSON

public class SanityClient {
    let urlSession = URLSession(configuration: .default)

    var config: Config

    enum ClientError: Error {
        case server(url: URL, code: Int)
        case missingData
    }

    public struct Config {
        let projectId: String
        let dataset: String
        let version: APIVersion
        let token: String?
        let useCdn: Bool?
        var apiHost: APIHost {
            // TODO: There are a few more conditions that will exclude CDN as a valid host, such as:
            // config with custom apihost domain
            // Any request that isnt GET or HEAD
            // Query Listening?
            if useCdn == true, token == nil {
                return .productionCDN
            }

            return .production
        }

        enum APIHost {
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
                request.setValue("Bearer: \(token)", forHTTPHeaderField: "Authorization")
            }

            return request
        }
    }

    public struct Query<T: Decodable> {
        let config: Config
        let query: String
        let params: [String: Any]
        let urlSession: URLSession

        enum apiURL {
            case fetch(query: String, params: [String: Any], config: Config)
            case listen(query: String, params: [String: Any], config: Config)

            var urlRequest: URLRequest {
                switch self {
                case let .fetch(query, params, config):
                    let queryItems = queryItems(defaults: [
                        "query": query,
                    ], params: params)

                    let path = "/data/query/\(config.dataset)"
                    return config.getURLRequest(path: path, queryItems: queryItems)

                case let .listen(query, params, config):
                    let queryItems = queryItems(defaults: [
                        "query": query,
                        "includeResult": "true",
                    ], params: params)

                    let path = "/data/listen/\(config.dataset)"
                    return config.getURLRequest(path: path, queryItems: queryItems)
                }
            }

            private func queryItems(defaults: [String: Any], params: [String: Any]) -> [URLQueryItem] {
                let mergedParams: [String: Any] = defaults.merging(params) { _, new in new }

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

    public init(config: Config) {
        self.config = config
    }

    public init(projectId: String, dataset: String, version: Config.APIVersion = .v20210325, token: String? = nil, useCdn: Bool? = nil) {
        self.config = Config(projectId: projectId, dataset: dataset, version: version, token: token, useCdn: useCdn)
    }

    public func query<T: Decodable>(_: T.Type, query: String, params: [String: Any] = [:]) -> Query<T> {
        Query<T>(config: config, query: query, params: params, urlSession: urlSession)
    }

    public func query(query: String, params: [String: Any] = [:]) -> Query<JSON> {
        Query<JSON>(config: config, query: query, params: params, urlSession: urlSession)
    }

    public func getURL(path: String) -> URL {
        config.getURL(path: path)
    }
}
