// MIT License
//
// Copyright (c) 2021 Sanity.io

import Combine
import EventSource
import Foundation

public extension SanityClient.Query where T: Decodable {
    struct ListenResponse<T: Decodable>: Decodable {
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

    struct ListenPublisher<T: Decodable>: Publisher {
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

    class ListenSubscription<Target: Subscriber, T: Decodable>: Subscription where Target.Input == ListenResponse<T> {
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
    func listen(reconnect: Bool = true, includeResult: Bool = true, includePreviousRevision: Bool? = nil, visibility: String? = nil) -> ListenPublisher<T> {
        let urlRequest = apiURL.listen(query: query, params: params, config: config, includeResult: includeResult, includePreviousRevision: includePreviousRevision, visibility: visibility).urlRequest

        let eventSource = EventSource(url: urlRequest.url!, headers: urlRequest.allHTTPHeaderFields ?? [:])

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
}
