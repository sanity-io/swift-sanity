// MIT License
//
// Copyright (c) 2021 Sanity.io

import Combine
import Foundation

public extension SanityClient.Query {
    typealias ResultCallback<Value> = (Result<Value, Error>) -> Void

    /// DataResponse is returned on a successful query
    struct DataResponse<T: Decodable>: Decodable {
        enum keys: String, CodingKey { case ms, query, result }

        /// Time taken on the server to process and execute the query
        public let ms: Int

        /// The submitted query
        public let query: String

        /// The query result
        public let result: T

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: keys.self)

            self.ms = try container.decode(Int.self, forKey: .ms)
            self.query = try container.decode(String.self, forKey: .query)
            self.result = try container.decode(T.self, forKey: .result)
        }
    }

    /// ErrorResponse is returned on a failed query. The error object can contains a queryError indicating that the server failed to process the query.
    /// For other errors(ie. invalid access token), query error wil not be set.
    /// See https://www.sanity.io/docs/http-query#vhAq6Djj for more information in regards of error handling
    struct ErrorResponse: Decodable, LocalizedError {
        public struct QueryError: Decodable {
            enum keys: String, CodingKey { case description, end, start, ms, query, type }

            /// Query syntax index on where the error starts
            public let start: Int

            /// Query syntax index on where the error ends
            public let end: Int

            /// Contains a description on what the server couldn't parse
            public let description: String

            /// The submitted and failed query
            public let query: String

            /// Type of error
            public let type: String

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: keys.self)

                self.description = try container.decode(String.self, forKey: .description)
                self.end = try container.decode(Int.self, forKey: .end)
                self.start = try container.decode(Int.self, forKey: .start)
                self.query = try container.decode(String.self, forKey: .query)
                self.type = try container.decode(String.self, forKey: .type)
            }

            public var queryError: String {
                let query = self.query
                let start = String.Index(utf16Offset: self.start, in: query)
                let end = String.Index(utf16Offset: self.end, in: query)
                return query[..<start] + " (here ->) " + query[end...]
            }
        }

        enum keys: String, CodingKey { case error, message, statusCode }

        /// queryError is an optional field indicated that the server could not process the given query
        public let queryError: QueryError?

        /// Error message
        public let message: String

        /// Status code is a http status code returned by the error object
        public let statusCode: Int

        /// Error is the type of error
        public let error: String

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: keys.self)

            if let queryError = try? container.decode(QueryError.self, forKey: .error) {
                self.queryError = queryError
                self.message = queryError.description
                self.error = queryError.type
                self.statusCode = 0
            } else {
                self.queryError = nil
                self.message = try container.decode(String.self, forKey: .message)
                self.statusCode = try container.decode(Int.self, forKey: .statusCode)
                self.error = try container.decode(String.self, forKey: .error)
            }
        }

        public var errorDescription: String? {
            NSLocalizedString(self.message, comment: self.error)
        }

        public var queryErrorDescription: String {
            guard let queryError = self.queryError else {
                return ""
            }

            return queryError.queryError
        }
    }

    /// Creates a Publisher that queries the Sanity Content Lake API, and emits `T` on a successful query and Error on failed queries
    ///
    /// # Example #
    /// ```
    /// client.query([String].self, query: groqQuery).fetch()
    /// .receive(on: DispatchQueue.main)
    /// .sink(receiveCompletion: { completion in
    ///     switch completion {
    ///         case .finished:
    ///         break
    ///     case let .failure(error):
    ///         self.error = error
    ///     }
    /// }, receiveValue: { response in
    ///     self.resultString = response.result
    ///     self.ms = response.ms
    ///     self.queryString = response.query
    /// })
    /// ```
    func fetch() -> AnyPublisher<DataResponse<T>, Error> {
        let urlRequest = apiURL.fetch(query: query, params: params, config: config).urlRequest

        return urlSession.dataTaskPublisher(for: urlRequest).tryMap { data, response -> JSONDecoder.Input in
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            switch httpResponse.statusCode {
            case 200 ..< 300:
                return data
            case 400 ..< 500:
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw errorResponse
            default:
                throw URLError(.badServerResponse)
            }
        }
        .decode(type: DataResponse<T>.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
    }

    /// Creates a fetch that retrieves the queries the Sanity Content Lake API, and calls a handler upon completion.
    ///
    /// # Example #
    /// ```
    /// client.query([String].self, query: groqQuery).fetch { completion in
    ///     switch(completion) {
    ///     case .success(let response):
    ///         dump(response.result)
    ///     case .failure(let error):
    ///         dump(error)
    ///     }
    /// }
    /// ```
    func fetch(completion: @escaping ResultCallback<DataResponse<T>>) {
        let urlRequest = apiURL.fetch(query: query, params: params, config: config).urlRequest

        let task = urlSession.dataTask(with: urlRequest) { data, response, _ in
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                return completion(.failure(URLError(.badServerResponse)))
            }

            let decoder = JSONDecoder()

            switch httpResponse.statusCode {
            case 200 ..< 300:
                do {
                    let data = try decoder.decode(DataResponse<T>.self, from: data)
                    completion(.success(data))
                } catch let e {
                    completion(.failure(e))
                }
            case 400 ..< 500:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    return completion(.failure(errorResponse))
                }
                fallthrough
            default:
                return completion(.failure(URLError(.badServerResponse)))
            }
        }

        task.resume()
    }
}
