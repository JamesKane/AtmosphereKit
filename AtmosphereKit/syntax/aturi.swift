//
//  aturi.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

class AtUri {
    var hash: String
    var host: String
    var pathname: String
    var searchParams: [URLQueryItem]
    
    // MARK: - Initializer
    init(uri: String, base: String? = nil) throws {
        if let base = base {
            guard let parsedBase = AtUri.parse(base) else {
                throw URLError.invalidURI("Invalid at uri: \(base)")
            }
            
            guard let parsedRelative = AtUri.parseRelative(uri) else {
                throw URLError.invalidURI("Invalid path: \(uri)")
            }
            
            self.hash = parsedRelative.hash
            self.host = parsedBase.host
            self.pathname = parsedRelative.pathname
            self.searchParams = parsedRelative.searchParams
        } else {
            guard let parsed = AtUri.parse(uri) else {
                throw URLError.invalidURI("Invalid at uri: \(uri)")
            }
            
            self.hash = parsed.hash
            self.host = parsed.host
            self.pathname = parsed.pathname
            self.searchParams = parsed.searchParams
        }
    }
    
    // MARK: - Static Factory Method
    static func make(handleOrDid: String, collection: String? = nil, rkey: String? = nil) throws -> AtUri {
        var uri = handleOrDid
        if let collection = collection {
            uri += "/\(collection)"
        }
        if let rkey = rkey {
            uri += "/\(rkey)"
        }
        return try AtUri(uri: uri)
    }

    // MARK: - Computed Properties
    var `protocol`: String {
        return "at:"
    }
    
    var origin: String {
        return "at://\(host)"
    }
    
    var hostname: String {
        get {
            return host
        }
        set {
            host = newValue
        }
    }
    
    var search: String {
        get {
            if searchParams.isEmpty { return "" }
            var components = URLComponents()
            components.queryItems = searchParams
            return components.query ?? ""
        }
        set {
            let components = URLComponents(string: "?\(newValue)")
            searchParams = components?.queryItems ?? []
        }
    }
    
    var collection: String {
        get {
            return pathname.components(separatedBy: "/").filter { !$0.isEmpty }.first ?? ""
        }
        set {
            var parts = pathname.components(separatedBy: "/").filter { !$0.isEmpty }
            if parts.isEmpty {
                parts.append(newValue)
            } else {
                parts[0] = newValue
            }
            pathname = parts.joined(separator: "/")
        }
    }
    
    var rkey: String {
        get {
            let parts = pathname.components(separatedBy: "/").filter { !$0.isEmpty }
            return parts.count > 1 ? parts[1] : ""
        }
        set {
            var parts = pathname.components(separatedBy: "/").filter { !$0.isEmpty }
            if parts.count < 1 {
                parts.append("undefined")
            }
            if parts.count == 1 {
                parts.append(newValue)
            } else {
                parts[1] = newValue
            }
            pathname = parts.joined(separator: "/")
        }
    }
    
    var href: String {
        return self.toString()
    }
    
    // MARK: - Conversion to String
    func toString() -> String {
        var path = pathname.isEmpty ? "/" : pathname
        if !path.starts(with: "/") {
            path = "/\(path)"
        }
        
        let query = search.isEmpty ? "" : "?\(search)"
        let hashString = hash.isEmpty ? "" : "#\(hash)"
        return "at://\(host)\(path)\(query)\(hashString)"
    }
    
    // MARK: - Parsing
    private static func parse(_ str: String) -> (hash: String, host: String, pathname: String, searchParams: [URLQueryItem])? {
        let atpRegex = #"""
        ^(at://)?((?:did:[a-z0-9:%-]+)|(?:[a-z0-9][a-z0-9.:-]*))(\/[^?#\s]*)?(\?[^#\s]+)?(#[^\s]+)?$
        """#
        
        guard let regex = try? NSRegularExpression(pattern: atpRegex, options: .caseInsensitive),
              let match = regex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.count)) else {
            return nil
        }
        
        let nsString = str as NSString
        let hash = nsString.substring(with: match.range(at: 5)).isEmpty ? "" : nsString.substring(with: match.range(at: 5))
        let host = nsString.substring(with: match.range(at: 2)).isEmpty ? "" : nsString.substring(with: match.range(at: 2))
        let pathname = nsString.substring(with: match.range(at: 3)).isEmpty ? "" : nsString.substring(with: match.range(at: 3))
        let searchParamsString = nsString.substring(with: match.range(at: 4)).isEmpty ? "" : nsString.substring(with: match.range(at: 4))
        let searchParams = URLComponents(string: searchParamsString)?.queryItems ?? []
        
        return (hash, host, pathname, searchParams)
    }
    
    private static func parseRelative(_ str: String) -> (hash: String, pathname: String, searchParams: [URLQueryItem])? {
        let relativeRegex = #"""
        ^(\/[^?#\s]*)?(\?[^#\s]+)?(#[^\s]+)?$
        """#
        
        guard let regex = try? NSRegularExpression(pattern: relativeRegex, options: []),
              let match = regex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.count)) else {
            return nil
        }
        
        let nsString = str as NSString
        let hash = nsString.substring(with: match.range(at: 3)).isEmpty ? "" : nsString.substring(with: match.range(at: 3))
        let pathname = nsString.substring(with: match.range(at: 1)).isEmpty ? "" : nsString.substring(with: match.range(at: 1))
        let searchParamsString = nsString.substring(with: match.range(at: 2)).isEmpty ? "" : nsString.substring(with: match.range(at: 2))
        let searchParams = URLComponents(string: searchParamsString)?.queryItems ?? []
        
        return (hash, pathname, searchParams)
    }
}

// MARK: - Custom Error
enum URLError: Error, LocalizedError {
    case invalidURI(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURI(let message):
            return message
        }
    }
}
