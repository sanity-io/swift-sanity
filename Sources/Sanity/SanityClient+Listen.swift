// MIT License
//
// Copyright (c) 2023 Sanity.io

import Combine
import EventSource
import Foundation

fileprivate let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

struct UnableToDecodeTimestamp: Error {
    let string: String
}

public extension SanityClient.Query where T: Decodable {
    struct ListenResponse: Decodable {
        enum keys: String, CodingKey { case eventId, documentId, transition, result, timestamp, resultRev, previousRev }
        public let eventId: String
        public let transition: String
        public let documentId: String
        public let timestamp: Date
        public let previousRev: String?
        public let resultRev: String
        public let result: T?

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: keys.self)

            self.eventId = try container.decode(String.self, forKey: .eventId)
            self.documentId = try container.decode(String.self, forKey: .documentId)
            self.transition = try container.decode(String.self, forKey: .transition)
            self.resultRev = try container.decode(String.self, forKey: .resultRev)
            self.previousRev = try? container.decode(String.self, forKey: .previousRev)
            self.result = try? container.decode(T.self, forKey: .result)
            let dateStr = try container.decode(String.self, forKey: .timestamp)
            guard let date = dateFormatter.date(from: dateStr) else {
                throw UnableToDecodeTimestamp(string: dateStr)
            }
            self.timestamp = date
        }
    }

    struct ListenPublisher: Publisher {
        public typealias Output = ListenResponse
        public typealias Failure = Never

        fileprivate var eventSource: EventSource
        fileprivate var reconnect: Bool

        public func receive<S: Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {
            let subscription = ListenSubscription<S>(eventSource: eventSource, reconnect: reconnect)
            subscription.target = subscriber

            subscriber.receive(subscription: subscription)

            eventSource.addEventListener("mutation", handler: subscription.trigger)
        }
    }

    class ListenSubscription<Target: Subscriber>: Subscription where Target.Input == ListenResponse {
        fileprivate var eventSource: EventSource
        fileprivate var reconnect: Bool

        var target: Target?

        public init(eventSource: EventSource, reconnect: Bool) {
            self.eventSource = eventSource
            self.reconnect = reconnect

            eventSource.onComplete { _, _, _ in
                if self.target != nil, self.reconnect {
                    eventSource.connect()
                }
            }

            eventSource.addEventListener("disconnect") { _, _, _ in
                self.cancel()
            }
        }

        public func request(_: Subscribers.Demand) {}

        public func cancel() {
            self.reconnect = false
            self.eventSource.disconnect()
            target = nil
        }

        func trigger(id _: String?, event _: String?, data: String?) {
            guard let data = data?.data(using: .utf8) else {
                return
            }

            guard let decoded = try? JSONDecoder().decode(ListenResponse.self, from: data) else {
                return
            }

            _ = target?.receive(decoded)
        }
    }

    /// Creates a Publisher that queries and listens to the Sanity Content Lake API, and emits `T` on mutation events
    ///
    /// # Example #
    /// ```
    /// client.query([String].self, query: groqQuery).listen()
    /// .receive(on: DispatchQueue.main)
    /// .sink { update in
    ///   self.resultString = response.result
    /// }
    /// ```
    ///
    /// See https://www.sanity.io/docs/listening for more information about listeners
    ///
    /// - Parameter reconnect: Wether or not to reconnect on connection close. Note that a failed GROQ query will lead to the Content Lake API closing the connection
    /// - Parameter includeResult: Include the resulting document in addition to the changes, defaults to true
    /// - Parameter includePreviousRevision: Include the document as it looked before the change.
    /// - Parameter visibility: Specifies whether events should be sent as soon as a transaction has been committed (transaction, default), or only after they are available for queries (query). Note that this is best-effort, and listeners with query may in certain cases (notably with deferred transactions) receive events that are not yet visible to queries. The visibility event field will indicate the actual visibility.
    ///
    /// - Returns: ListenPublisher<T>
    func listen(reconnect: Bool = true, includeResult: Bool = true, includePreviousRevision: Bool? = nil, visibility: String? = nil) -> ListenPublisher {
        let urlRequest = apiURL.listen(query: query, params: params, config: config, includeResult: includeResult, includePreviousRevision: includePreviousRevision, visibility: visibility).urlRequest

        let eventSource = EventSource(url: urlRequest.url!, headers: urlRequest.allHTTPHeaderFields ?? [:])

        eventSource.connect()

        return ListenPublisher(eventSource: eventSource, reconnect: reconnect)
    }
}

public extension SanityClient.Query {
    struct ListenDataPublisher: Publisher {
        public typealias Output = Data
        public typealias Failure = Never

        fileprivate var eventSource: EventSource
        fileprivate var reconnect: Bool

        public func receive<S: Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {
            let subscription = ListenDataSubscription<S>(eventSource: eventSource, reconnect: reconnect)
            subscription.target = subscriber

            subscriber.receive(subscription: subscription)

            eventSource.addEventListener("mutation", handler: subscription.trigger)
        }
    }

    class ListenDataSubscription<Target: Subscriber>: Subscription where Target.Input == Data {
        fileprivate var eventSource: EventSource

        var target: Target?
        var reconnect: Bool

        public init(eventSource: EventSource, reconnect: Bool) {
            self.eventSource = eventSource
            self.reconnect = reconnect

            eventSource.onComplete { _, _, _ in
                if self.target != nil, self.reconnect {
                    eventSource.connect()
                }
            }

            eventSource.addEventListener("disconnect") { _, _, _ in
                self.cancel()
            }
        }

        public func request(_: Subscribers.Demand) {}

        public func cancel() {
            self.reconnect = false
            self.eventSource.disconnect()
            target = nil
        }

        func trigger(id _: String?, event _: String?, data: String?) {
            guard let data = data?.data(using: .utf8) else {
                return
            }

            _ = target?.receive(data)
        }
    }

    /// Creates a Publisher that queries and listens to the Sanity Content Lake API, and emits `T` on mutation events
    ///
    /// # Example #
    /// ```
    /// client.query([String].self, query: groqQuery).listen()
    /// .receive(on: DispatchQueue.main)
    /// .sink { data in
    ///   self.resultString = String(data: data, encoding: .utf8)
    /// }
    /// ```
    ///
    /// See https://www.sanity.io/docs/listening for more information about listeners
    ///
    /// - Parameter reconnect: Wether or not to reconnect on connection close. Note that a failed GROQ query will lead to the Content Lake API closing the connection
    /// - Parameter includeResult: Include the resulting document in addition to the changes, defaults to true
    /// - Parameter includePreviousRevision: Include the document as it looked before the change.
    /// - Parameter visibility: Specifies whether events should be sent as soon as a transaction has been committed (transaction, default), or only after they are available for queries (query). Note that this is best-effort, and listeners with query may in certain cases (notably with deferred transactions) receive events that are not yet visible to queries. The visibility event field will indicate the actual visibility.
    ///
    /// - Returns: ListenPublisher<T>
    func listen(reconnect: Bool = true, includeResult: Bool = true, includePreviousRevision: Bool? = nil, visibility: String? = nil) -> ListenDataPublisher {
        let urlRequest = apiURL.listen(query: query, params: params, config: config, includeResult: includeResult, includePreviousRevision: includePreviousRevision, visibility: visibility).urlRequest

        let eventSource = EventSource(url: urlRequest.url!, headers: urlRequest.allHTTPHeaderFields ?? [:])

        eventSource.connect()

        return ListenDataPublisher(eventSource: eventSource, reconnect: reconnect)
    }
}
