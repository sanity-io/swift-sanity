//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

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

    func fetch() -> AnyPublisher<DataResponse<T>, Error> {
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

    func fetch(completion: @escaping ResultCallback<DataResponse<T>>) {
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
}
