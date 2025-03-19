//
//  nsid.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

struct InvalidNsidError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

struct NSID {
    var segments: [String] = []
    
    // Static method to parse an NSID
    static func parse(_ nsid: String) throws -> NSID {
        return try NSID(nsid: nsid)
    }
    
    // Static method to create an NSID from authority and name
    static func create(authority: String, name: String) throws -> NSID {
        let segments = authority.split(separator: ".").reversed() + [Substring(name)]
        let joinedSegments = segments.joined(separator: ".")
        return try NSID(nsid: joinedSegments)
    }
    
    // Static method to check if an NSID is valid
    static func isValid(_ nsid: String) -> Bool {
        do {
            _ = try NSID.parse(nsid)
            return true
        } catch {
            return false
        }
    }
    
    // Initializer with validation
    init(nsid: String) throws {
        try NSID.ensureValidNsid(nsid: nsid)
        self.segments = nsid.split(separator: ".").map { String($0) }
    }
    
    // Computed property for authority
    var authority: String {
        // Use explicit range creation
        let endIndex = max(0, segments.count - 1) // Safeguard for negative values
        return segments[0..<endIndex].reversed().joined(separator: ".")
    }
    
    // Computed property for name
    var name: String? {
        return segments.last
    }
    
    // Convert NSID back to string
    func toString() -> String {
        return segments.joined(separator: ".")
    }
    
    // Validation logic for NSID
    static func ensureValidNsid(nsid: String) throws {
        // Check that all characters are allowed
        guard nsid.range(of: "^[a-zA-Z0-9.-]*$", options: .regularExpression) != nil else {
            throw InvalidNsidError(message: "Disallowed characters in NSID (ASCII letters, digits, dashes, periods only)")
        }
        
        // Check maximum length
        if nsid.count > 317 {
            throw InvalidNsidError(message: "NSID is too long (317 chars max)")
        }
        
        // Split labels and validate each part
        let labels = nsid.split(separator: ".")
        if labels.count < 3 {
            throw InvalidNsidError(message: "NSID needs at least three parts")
        }
        
        for (index, label) in labels.enumerated() {
            if label.count < 1 {
                throw InvalidNsidError(message: "NSID parts cannot be empty")
            }
            if label.count > 63 {
                throw InvalidNsidError(message: "NSID part too long (max 63 chars)")
            }
            if label.hasPrefix("-") || label.hasSuffix("-") {
                throw InvalidNsidError(message: "NSID parts cannot start or end with a hyphen")
            }
            if index == 0, label.first?.isNumber == true {
                throw InvalidNsidError(message: "NSID first part may not start with a digit")
            }
            if index == labels.count - 1, label.range(of: "^[a-zA-Z][a-zA-Z0-9]*$", options: .regularExpression) == nil {
                throw InvalidNsidError(message: "NSID name part must be only letters and digits (and no leading digit)")
            }
        }
    }
}

extension String {
    func matches(regex: String) -> Bool {
        do {
            let regex = try Regex(regex)
            return self.wholeMatch(of: regex) != nil
        } catch {
            return false
        }
    }
}
