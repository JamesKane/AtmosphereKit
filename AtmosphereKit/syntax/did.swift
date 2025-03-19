//
//  did.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

// Custom Error for Invalid DIDs
struct InvalidDidError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

// Utility to ensure a valid DID according to the provided constraints
struct DidValidator {
    // MARK: - Validation Methods
    
    static func ensureValidDid(_ did: String) throws {
        // Must start with "did:"
        guard did.starts(with: "did:") else {
            throw InvalidDidError(message: "DID requires \"did:\" prefix")
        }
        
        // Check if all characters are valid ASCII (letters, digits, and other allowed symbols)
        let allowedAsciiPattern = "^[a-zA-Z0-9._:%-]*$"
        if !did.matches(regex: allowedAsciiPattern) {
            throw InvalidDidError(message: "Disallowed characters in DID (ASCII letters, digits, and a couple other characters only)")
        }
        
        // Split into components and ensure proper format
        let components = did.split(separator: ":")
        guard components.count >= 3 else {
            throw InvalidDidError(message: "DID requires prefix, method, and method-specific content")
        }
        
        // Ensure the method (second segment) is only lowercase letters
        let method = String(components[1])
        if !method.matches(regex: "^[a-z]+$") {
            throw InvalidDidError(message: "DID method must be lower-case letters")
        }
        
        // Check that it doesn't end with ":" or "%"
        if did.hasSuffix(":") || did.hasSuffix("%") {
            throw InvalidDidError(message: "DID cannot end with \":\" or \"%\"")
        }
        
        // Check the maximum length constraint (2048 characters)
        if did.count > 2048 {
            throw InvalidDidError(message: "DID is too long (2048 chars max)")
        }
    }
    
    static func ensureValidDidRegex(_ did: String) throws {
        // Regex to enforce constraints directly
        let regexPattern = #"^did:[a-z]+:[a-zA-Z0-9._:%-]*[a-zA-Z0-9._-]$"#
        if !did.matches(regex: regexPattern) {
            throw InvalidDidError(message: "DID didn't validate via regex")
        }
        
        // Check the maximum length constraint (2048 characters)
        if did.count > 2048 {
            throw InvalidDidError(message: "DID is too long (2048 chars max)")
        }
    }
}
