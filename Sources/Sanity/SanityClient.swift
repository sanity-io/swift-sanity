//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

import Combine
import EventSource
import Foundation
import GenericJSON

public class SanityClient {
    private var urlSession = URLSession(configuration: .default)

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
                    return "v2020-03-25"
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

        public typealias ResultCallback<Value> = (Result<Value, Error>) -> Void

        public struct DataResponse<T: Decodable>: Decodable {
            enum keys: String, CodingKey { case ms, query, result }
            public let ms: Int
            public let query: String
            public let result: T

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: keys.self)

                self.ms = try container.decode(Int.self, forKey: .ms)
                self.query = try container.decode(String.self, forKey: .query)
                self.result = try container.decode(T.self, forKey: .result)
            }
        }

        public struct ListenResponse<T: Decodable>: Decodable {
            enum keys: String, CodingKey { case eventId, transition, result }
            public let eventId: String
            public let transition: String
            public let result: T

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: keys.self)

                self.eventId = try container.decode(String.self, forKey: .eventId)
                self.transition = try container.decode(String.self, forKey: .transition)
                self.result = try container.decode(T.self, forKey: .result)
            }
        }

        public struct ErrorResponse: Decodable {
            struct Error: LocalizedError, Decodable {
                enum keys: String, CodingKey { case description, end, start, ms, query, type }
                let end: Int
                let start: Int
                let description: String
                let query: String
                let type: String

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: keys.self)

                    self.description = try container.decode(String.self, forKey: .description)
                    self.end = try container.decode(Int.self, forKey: .end)
                    self.start = try container.decode(Int.self, forKey: .start)
                    self.query = try container.decode(String.self, forKey: .query)
                    self.type = try container.decode(String.self, forKey: .type)
                }

                public var errorDescription: String? {
                    NSLocalizedString(self.description, comment: self.type)
                }

                var queryErrorDescription: String {
                    let query = self.query
                    let start = String.Index(utf16Offset: self.start, in: query)
                    let end = String.Index(utf16Offset: self.end, in: query)
                    return query[..<start] + " (here ->) " + query[end...]
                }
            }

            let error: ErrorResponse.Error
        }

        public func fetch() -> AnyPublisher<DataResponse<T>, Error> {
            let url = apiURL.fetch(query: query, params: params, config: config).url

            return urlSession.dataTaskPublisher(for: url).tryMap { data, response -> JSONDecoder.Input in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                switch httpResponse.statusCode {
                case 200:
                    return data
                case 400:
                    let errorEnvelope = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    throw errorEnvelope.error
                default:
                    throw URLError(.badServerResponse)
                }
            }
            .decode(type: DataResponse<T>.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
        }

        public func fetch(completion: @escaping ResultCallback<DataResponse<T>>) {
            let url = apiURL.fetch(query: query, params: params, config: config).url

            let task = urlSession.dataTask(with: url) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                    return completion(.failure(URLError(.badServerResponse)))
                }

                switch httpResponse.statusCode {
                case 200:
                    do {
                        let decoder = JSONDecoder()
                        let data = try decoder.decode(DataResponse<T>.self, from: data)

                        completion(.success(data))
                    } catch {
                        completion(.failure(error))
                    }
                case 400:
                    if let errorEnvelope = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        return completion(.failure(errorEnvelope.error))
                    }
                    fallthrough
                default:
                    return completion(.failure(URLError(.badServerResponse)))
                }
            }

            task.resume()
        }

        public func listen(reconnect: Bool = true) -> ListenPublisher<T> {
            let url = apiURL.listen(query: query, params: params, config: config).url
            let eventSource = EventSource(url: url)

            eventSource.onMessage { id, event, data in
                print("message: \(String(describing: id)), event: \(String(describing: event)), data: \(String(describing: data))")
            }
            eventSource.onOpen {
                print("listen open")
            }
            eventSource.addEventListener("mutation") { id, event, data in
                print("mutation: \(String(describing: id)), event: \(String(describing: event)), data: \(String(describing: data))")
            }

            eventSource.connect()

            return ListenPublisher<T>(eventSource: eventSource, reconnect: reconnect)
        }

        public struct ListenPublisher<T: Decodable>: Publisher {
            // Declaring that our publisher doesn't emit any values,
            // and that it can never fail:
            public typealias Output = ListenResponse<T>
            public typealias Failure = Never

            fileprivate var eventSource: EventSource
            fileprivate var reconnect: Bool

            // Combine will call this method on our publisher whenever
            // a new object started observing it. Within this method,
            // we'll need to create a subscription instance and
            // attach it to the new subscriber:
            public func receive<S: Subscriber>(
                subscriber: S
            ) where S.Input == Output, S.Failure == Failure {
                // Creating our custom subscription instance:
                let subscription = ListenSubscription<S, T>(eventSource: eventSource, reconnect: reconnect)
                subscription.target = subscriber

                // Attaching our subscription to the subscriber:
                subscriber.receive(subscription: subscription)

                // Connecting our subscription to the control that's
                // being observed:
                eventSource.addEventListener("mutation", handler: subscription.trigger)
            }
        }

        public class ListenSubscription<Target: Subscriber, T: Decodable>: Subscription where Target.Input == ListenResponse<T> {
            fileprivate var eventSource: EventSource

            var target: Target?

            public init(eventSource: EventSource, reconnect: Bool) {
                self.eventSource = eventSource

                eventSource.onComplete { _, _, _ in
                    print("listen complete")

                    if self.target != nil, reconnect {
                        print("listen reconnecting")
                        eventSource.connect()
                    }
                }

                eventSource.addEventListener("disconnect") { _, _, _ in
                    self.cancel()
                }
            }

            // This subscription doesn't respond to demand, since it'll
            // simply emit events according to its underlying UIControl
            // instance, but we still have to implement this method
            // in order to conform to the Subscription protocol:
            public func request(_: Subscribers.Demand) {}

            public func cancel() {
                // When our subscription was cancelled, we'll release
                // the reference to our target to prevent any
                // additional events from being sent to it:
                self.eventSource.disconnect()
                target = nil
            }

            func trigger(id _: String?, event: String?, data: String?) {
                // Whenever an event was triggered by the underlying
                // UIControl instance, we'll simply pass Void to our
                // target to emit that event:
                let decoder = JSONDecoder()
                print("got data: \(String(describing: event)) \(String(describing: data))")
                do {
                    guard let data = data?.data(using: .utf8) else {
                        print("data missing")
                        return
                    }

                    let decoded = try decoder.decode(ListenResponse<T>.self, from: data)

                    _ = target?.receive(decoded)
                } catch {
                    print("Could not decode: \(error)")
                }
            }
        }

        private enum apiURL {
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
                    let paths: [String] = [config.version.string, "data", "query", config.dataset]
                    return getURLForPaths(paths, queryItems: queryItems, config: config)

                case let .listen(query, params, config):
                    var queryItems: [URLQueryItem] = [
                        .init(name: "query", value: query),
                        .init(name: "includeResult", value: "true"),
                    ] + parseParams(params)

                    if let apiKey = config.apiKey {
                        queryItems.append(.init(name: "apiKey", value: apiKey))
                    }

                    let paths: [String] = [config.version.string, "data", "listen", config.dataset]
                    return getURLForPaths(paths, queryItems: queryItems, config: config)
                }
            }

            private func getURLForPaths(_ paths: [String], queryItems: [URLQueryItem], config: Config) -> URL {
                var components = URLComponents()
                components.scheme = "https"
                components.host = config.apiHost.hostForProjectId(config.projectId)

                components.path = "/" + paths.joined(separator: "/")
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
