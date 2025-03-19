//
//  handle.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

// MARK: - Custom Errors
struct InvalidHandleError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

struct ReservedHandleError: Error, LocalizedError {} // Deprecated as per the original comment

// MARK: - Constants
private let INVALID_HANDLE = "handle.invalid"

// List of disallowed TLDs
private let DISALLOWED_TLDS: [String] = [
    ".local", ".arpa", ".invalid", ".localhost", ".internal", ".example",
    ".alt", ".onion"
]

// MARK: - Handle Utilities
struct HandleValidator {
    
    // Ensure that the given handle is valid
    static func ensureValidHandle(_ handle: String) throws {
        // 1. Check for valid characters
        let validCharRegex = "^[a-zA-Z0-9.-]*$"
        guard handle.matches(regex: validCharRegex) else {
            throw InvalidHandleError(message: "Disallowed characters in handle (ASCII letters, digits, dashes, periods only)")
        }
        
        // 2. Check the overall length
        if handle.count > 253 {
            throw InvalidHandleError(message: "Handle is too long (253 chars max)")
        }
        
        // 3. Split into labels
        let labels = handle.split(separator: ".")
        if labels.count < 2 {
            throw InvalidHandleError(message: "Handle domain needs at least two parts")
        }
        
        for (index, label) in labels.enumerated() {
            let labelStr = String(label)
            
            // 4. Check label length
            if labelStr.count < 1 {
                throw InvalidHandleError(message: "Handle parts cannot be empty")
            } else if labelStr.count > 63 {
                throw InvalidHandleError(message: "Handle part too long (max 63 chars)")
            }
            
            // 5. Check that labels do not start or end with hyphens
            if labelStr.hasPrefix("-") || labelStr.hasSuffix("-") {
                throw InvalidHandleError(message: "Handle parts cannot start or end with hyphens")
            }
            
            // 6. Check that the final component (TLD) starts with an ASCII letter
            if index == labels.count - 1, !labelStr.matches(regex: "^[a-zA-Z]") {
                throw InvalidHandleError(message: "Handle final component (TLD) must start with an ASCII letter")
            }
        }
    }
    
    // Simple regex-based validation
    static func ensureValidHandleRegex(_ handle: String) throws {
        let regex = #"^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$"#
        guard handle.matches(regex: regex) else {
            throw InvalidHandleError(message: "Handle didn't validate via regex")
        }
        
        // Check the overall length
        if handle.count > 253 {
            throw InvalidHandleError(message: "Handle is too long (253 chars max)")
        }
    }
    
    // Normalize a handle (convert to lower case)
    static func normalizeHandle(_ handle: String) -> String {
        return handle.lowercased()
    }
    
    // Normalize and validate handle
    static func normalizeAndEnsureValidHandle(_ handle: String) throws -> String {
        let normalized = normalizeHandle(handle)
        try ensureValidHandle(normalized)
        return normalized
    }
    
    // Check if the handle is valid (boolean result)
    static func isValidHandle(_ handle: String) -> Bool {
        do {
            try ensureValidHandle(handle)
            return true
        } catch is InvalidHandleError {
            return false
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }
    
    // Check if the TLD of the handle is valid
    static func isValidTld(_ handle: String) -> Bool {
        return !DISALLOWED_TLDS.contains(where: { handle.hasSuffix($0) })
    }
}
