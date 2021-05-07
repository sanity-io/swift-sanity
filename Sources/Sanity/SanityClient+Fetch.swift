// MIT License
//
// Copyright (c) 2021 Sanity.io

import Combine
import Foundation

public extension SanityClient.Query {
    typealias ResultCallback<Value> = (Result<Value, Error>) -> Void

    struct DataResponse<T: Decodable>: Decodable {
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

    struct ErrorResponse: Decodable {
        enum keys: String, CodingKey { case message, statusCode, error }

        let message: String
        let statusCode: Int
        let errorMessage: String

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: keys.self)
            self.message = try container.decode(String.self, forKey: .message)
            self.statusCode = try container.decode(Int.self, forKey: .statusCode)
            self.errorMessage = try container.decode(String.self, forKey: .error)
        }

        struct Error: LocalizedError {
            var errorResponse: ErrorResponse
            init(response: ErrorResponse) {
                self.errorResponse = response
            }

            var recoverySuggestion: String? {
                self.errorResponse.message
            }

            var failureReason: String? {
                self.errorResponse.errorMessage
            }
        }

        var error: Error {
            Error(response: self)
        }
    }

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
                let errorEnvelope = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw errorEnvelope.error
            default:
                throw URLError(.badServerResponse)
            }
        }
        .decode(type: DataResponse<T>.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
    }

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
}
