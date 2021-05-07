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
        let apiKey: String?
        let apiHost: APIHost = .productionCDN

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
    }

    public struct Query<T: Decodable> {
        let config: Config
        let query: String
        let params: [String: Any]
        let urlSession: URLSession

        enum apiURL {
            case fetch(query: String, params: [String: Any], config: Config)
            case listen(query: String, params: [String: Any], config: Config)

            var url: URL {
                switch self {
                case let .fetch(query, params, config):
                    var queryItems: [URLQueryItem] = [
                        .init(name: "query", value: query),
                    ] + self.parseParams(params)

                    if let apiKey = config.apiKey {
                        queryItems.append(.init(name: "apiKey", value: apiKey))
                    }
                    let paths: [String] = ["data", "query", config.dataset]
                    return getURLForPaths(paths, queryItems: queryItems, config: config)

                case let .listen(query, params, config):
                    var queryItems: [URLQueryItem] = [
                        .init(name: "query", value: query),
                        .init(name: "includeResult", value: "true"),
                    ] + parseParams(params)

                    if let apiKey = config.apiKey {
                        queryItems.append(.init(name: "apiKey", value: apiKey))
                    }

                    let paths: [String] = ["data", "listen", config.dataset]
                    return getURLForPaths(paths, queryItems: queryItems, config: config)
                }
            }

            private func getURLForPaths(_ paths: [String], queryItems: [URLQueryItem], config: Config) -> URL {
                var components = URLComponents()
                components.scheme = "https"
                components.host = config.apiHost.hostForProjectId(config.projectId)

                components.path = "/" + config.version.string + "/" + paths.joined(separator: "/")
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

    public init(projectId: String, dataset: String, version: Config.APIVersion = .v20210325, apiKey: String? = nil) {
        self.config = Config(projectId: projectId, dataset: dataset, version: version, apiKey: apiKey)
    }

    public func query<T: Decodable>(_: T.Type, query: String, params: [String: Any] = [:]) -> Query<T> {
        Query<T>(config: config, query: query, params: params, urlSession: urlSession)
    }

    public func query(query: String, params: [String: Any] = [:]) -> Query<JSON> {
        Query<JSON>(config: config, query: query, params: params, urlSession: urlSession)
    }
}
