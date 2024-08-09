//
//  AppStoreLookupService.swift
//  AppStoreLookup
//
//  Created by Pavel Yevtukhov on 02.08.2024.
//

import Foundation

protocol StoreUrlServiceInterface {
    func getStoreUrl(bundleId: String, completion: @escaping (Result<String, Error>) -> Void)
}

enum LookupError: Error, LocalizedError {
    case notFound
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .notFound:
            return NSLocalizedString("The App was not found", comment: "")
        case .invalidRequest:
            return NSLocalizedString("The URL or the request is incorrect", comment: "")
        }
    }
}

struct LookupResponse: Decodable {
    struct Result: Decodable {
        let trackViewUrl: String?

        /* Other fields
         let trackName: String?
         let minimumOsVersion: String?
         etc ...
        */
    }

    let results: [Result]?
}

final class AppStoreLookupService {
    func getStoreUrl(bundleId: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            getStoreUrl(bundleId: bundleId) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func removeEverythingAfterQuestionMark(from string: String) -> String {
        guard let questionMarkRange = string.range(of: "?") else {
            return string
        }
        return String(string[..<questionMarkRange.lowerBound])
    }
}

extension AppStoreLookupService: StoreUrlServiceInterface {
    func getStoreUrl(bundleId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlStr = "https://itunes.apple.com/lookup"
        guard var components = URLComponents(string: urlStr) else {
            completion(.failure(LookupError.invalidRequest))
            return
        }
        components.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleId)
        ]
        guard let url = components.url else {
            completion(.failure(LookupError.invalidRequest))
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error  in
            guard let self else { return }
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else { return }
            do {
                let lookupResponse: LookupResponse = try JSONDecoder().decode(LookupResponse.self, from: data)

                guard let trackViewUrl = lookupResponse.results?.first?.trackViewUrl,
                      !trackViewUrl.isEmpty else {
                    completion(.failure(LookupError.notFound))
                    return
                }
                let url = removeEverythingAfterQuestionMark(from: trackViewUrl)

                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
