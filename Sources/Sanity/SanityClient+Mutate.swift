// MIT License
//
// Copyright (c) 2023 Sanity.io

import Combine
import Foundation

public typealias SanityDocument = [String: Any]

public struct Patch {
    let path: String
    let operation: PatchOperation

    public init(_ path: String, operation: PatchOperation) {
        self.path = path
        self.operation = operation
    }

    func encode(documentId: String, ifRevisionId: String? = nil) -> Any {
        switch operation {
        case let .set(value):
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "set": [
                    path: value,
                ],
            ]
        case .unset:
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "unset": path,
            ]
        case let .setIfMissing(value):
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "setIfMissing": [
                    path: value,
                ],
            ]
        case let .insert(items, insertPosition):
            let strInsertPosition = "\(insertPosition)"
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "insert": [
                    strInsertPosition: path,
                    "items": items,
                ],
            ]
        case let .replace(items):
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "insert": [
                    "replace": path,
                    "items": items,
                ],
            ]
        case let .inc(amount):
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "inc": [
                    path: amount,
                ],
            ]
        case let .dec(amount):
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "dec": [
                    path: amount,
                ],
            ]
        case let .diffMatchPatch(patch):
            return [
                "id": documentId,
                "ifRevisionID": ifRevisionId as Any,
                "diffMatchPatch": [
                    path: patch,
                ],
            ]
        }
    }
}

public enum Mutation {
    case create(document: SanityDocument)
    case createIfNotExists(document: SanityDocument)
    case createOrReplace(document: SanityDocument)

    case patch(documentId: String, patches: [Patch], ifRevisionId: String? = nil)
    case delete(documentId: String)

    func encode() -> [[String: Any]]? {
        switch self {
        case let .create(document: document):
            return [["create": document]]

        case let .createIfNotExists(document: document):
            return [["createIfNotexists": document]]

        case let .createOrReplace(document: document):
            return [["createOrReplace": document]]

        case let .delete(documentId):
            return [["delete": ["id": documentId]]]

        case let .patch(documentId, patches, ifRevisionId):
            if patches.count == 0 {
                return nil
            }
            return patches.map { patch in
                ["patch": patch.encode(documentId: documentId, ifRevisionId: ifRevisionId)]
            }
        }
    }
}

public enum InsertPosition: String {
    case before
    case after
}

public enum PatchOperation {
    case set(Any)
    case unset
    case setIfMissing(Any)

    case insert(Any, InsertPosition = .after)
    case replace(Any)

    // Numeric operations
    case inc(Int?)
    case dec(Int?)

    // String operations
    case diffMatchPatch(String)
}

public extension SanityClient.Transaction {
    struct Response: Codable {
        struct MutationResult: Codable {
            enum MutationOperation: String, Codable {
                case create
                case delete
                case update
                case none
            }

            let operation: MutationOperation
        }

        let transactionId: String
        let results: [MutationResult]
        let documentIds: [String]?
    }

    struct ErrorResponse: Decodable, LocalizedError {
        struct MutationError: Decodable {
            let type: String
            let description: String
        }

        let error: MutationError

        public var errorDescription: String? {
            NSLocalizedString(self.error.description, comment: self.error.type)
        }
    }

    enum Visibility: String {
        case sync
        case async
        case deferred
    }

    private func getQueryItems(returnIds: Bool?, returnDocuments: Bool?, visbility: Visibility?, dryRun: Bool?) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        if let returnIds {
            queryItems.append(URLQueryItem(name: "returnIds", value: "\(returnIds)"))
        }
        if let returnDocuments {
            queryItems.append(URLQueryItem(name: "returnDocuments", value: "\(returnDocuments)"))
        }
        if let visbility {
            queryItems.append(URLQueryItem(name: "visbility", value: "\(visbility)"))
        }
        if let dryRun {
            queryItems.append(URLQueryItem(name: "dryRun", value: "\(dryRun)"))
        }
        return queryItems
    }

    func commit(returnIds: Bool? = nil, returnDocuments: Bool? = nil, visbility: Visibility? = nil, dryRun: Bool? = nil) async -> Result<Response, Error> {
        let queryItems = getQueryItems(returnIds: returnIds, returnDocuments: returnDocuments, visbility: visbility, dryRun: dryRun)

        guard let body = try? self.encode() else {
            return .failure(NSError(domain: "Failed to encode mutations", code: -10001, userInfo: nil))
        }

        let urlRequest = config.getURLRequest(path: "/data/mutate/\(config.dataset)", body: body, queryItems: queryItems)
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            switch httpResponse.statusCode {
            case 200 ..< 300:
                return try .success(JSONDecoder().decode(Response.self, from: data))
            case 400 ..< 500:
                throw try JSONDecoder().decode(ErrorResponse.self, from: data)
            default:
                throw URLError(.badServerResponse)
            }
        } catch {
            return .failure(error)
        }
    }

    typealias ResultCallback<Value> = (Result<Value, Error>) -> Void
    func commit(returnIds: Bool? = nil, returnDocuments: Bool? = nil, visbility: Visibility? = nil, dryRun: Bool? = nil, completion: @escaping ResultCallback<Response>) {
        let queryItems = getQueryItems(returnIds: returnIds, returnDocuments: returnDocuments, visbility: visbility, dryRun: dryRun)

        guard let body = try? self.encode() else {
            return completion(.failure(NSError(domain: "Failed to encode mutations", code: -10001, userInfo: nil)))
        }

        let urlRequest = config.getURLRequest(path: "/data/mutate/\(config.dataset)", body: body, queryItems: queryItems)
        let task = urlSession.dataTask(with: urlRequest) { data, response, _ in
            guard let httpResponse = response as? HTTPURLResponse, let data else {
                return completion(.failure(URLError(.badServerResponse)))
            }

            do {
                switch httpResponse.statusCode {
                case 200 ..< 300:
                    return try completion(.success(JSONDecoder().decode(Response.self, from: data)))
                case 400 ..< 500:
                    throw try JSONDecoder().decode(ErrorResponse.self, from: data)
                default:
                    throw URLError(.badServerResponse)
                }
            } catch let e {
                completion(.failure(e))
            }
        }

        task.resume()
    }
}

public extension SanityClient {
    /// Creates a transaction with the given mutations and commits them
    ///
    /// - Parameter mutations: Array of mutations to send
    ///
    /// - Returns: async Result<SanityClient.Transaction.Response, Error>
    func mutate(_ mutations: [Mutation]) async -> Result<Transaction.Response, Error> {
        await Transaction(config: config, mutations: mutations, urlSession: urlSession).commit()
    }

    /// Creates a transaction with the given mutations, commits them, and calls the completion handler
    ///
    /// - Parameter mutations: Array of mutations to send
    /// - Parameter completion: Callback with the type Transaction.ResultCallback<Transaction.Response>
    ///
    /// - Returns: Void
    func mutate(_ mutations: [Mutation], completion: @escaping Transaction.ResultCallback<Transaction.Response>) {
        Transaction(config: config, mutations: mutations, urlSession: urlSession).commit(completion: completion)
    }
}
