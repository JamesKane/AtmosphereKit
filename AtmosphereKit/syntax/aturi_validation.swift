//
//  aturi_validation.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

// MARK: - ATURI Utility
struct AtUriValidator {
    
    // MARK: - Public Methods
    
    static func ensureValidAtUri(_ uri: String) throws {
        // Step 1: Split URI for fragment handling
        let uriParts = uri.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        if uriParts.count > 2 {
            throw AtUriError("ATURI can have at most one \"#\", separating fragment out")
        }
        let uriWithoutFragment = String(uriParts[0])
        let fragmentPart = uriParts.count == 2 ? String(uriParts[1]) : nil
        
        // Step 2: Validate ASCII characters
        let asciiRegex = #"^[a-zA-Z0-9._~:@!$\&'\)\(\*\+,;=%/-]*$"#
        guard uriWithoutFragment.matches(regex: asciiRegex) else {
            throw AtUriError("Disallowed characters in ATURI (ASCII)")
        }
        
        // Step 3: Split URI into components to check "authority" and path
        let parts = uriWithoutFragment.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count >= 3, parts[0] == "at:", parts[1].isEmpty else {
            throw AtUriError("ATURI must start with \"at://\"")
        }

        // Step 4: Validate the "authority" section
        let authority = String(parts[2])
        do {
            if authority.starts(with: "did:") {
                try DidValidator.ensureValidDid(authority) // Replace with corresponding DID validator
            } else {
                try HandleValidator.ensureValidHandle(authority) // Replace with handle validator
            }
        } catch {
            throw AtUriError("ATURI authority must be a valid handle or DID")
        }

        // Step 5: Validate the first path segment as valid NSID, if present
        if parts.count >= 4 {
            let firstPathSegment = String(parts[3])
            guard !firstPathSegment.isEmpty else {
                throw AtUriError("ATURI cannot have a slash after authority without a path segment")
            }
            do {
                try NSID.ensureValidNsid(nsid: firstPathSegment) // Replace with NSID validator
            } catch {
                throw AtUriError("ATURI requires first path segment (if supplied) to be a valid NSID")
            }
        }

        // Step 6: Validate the record key (rkey) if present
        if parts.count >= 5 {
            let secondPathSegment = String(parts[4])
            guard !secondPathSegment.isEmpty else {
                throw AtUriError("ATURI cannot have a slash after collection, unless record key is provided")
            }
            // Assuming no strict validation is needed for rkey based on comments
        }

        // Step 7: Ensure no more than two path components
        guard parts.count <= 5 else {
            throw AtUriError("ATURI path can have at most two parts, and no trailing slash")
        }

        // Step 8: Validate the fragment part, if present
        if let fragment = fragmentPart {
            guard !fragment.isEmpty, fragment.starts(with: "/") else {
                throw AtUriError("ATURI fragment must be non-empty and start with slash")
            }
            guard fragment.matches(regex: #"^\/[a-zA-Z0-9._~:@!$\&'\)\(\*\+,;=%\[\]/-]*$"#) else {
                throw AtUriError("Disallowed characters in ATURI fragment (ASCII)")
            }
        }

        // Step 9: Ensure the URI total length does not exceed 8 kilobytes
        guard uri.count <= 8 * 1024 else {
            throw AtUriError("ATURI is far too long")
        }
    }

    // Simplified Regex Validation for ATURI
    static func ensureValidAtUriRegex(_ uri: String) throws {
        let aturiRegex = #"^at:\/\/(?<authority>[a-zA-Z0-9._:%-]+)(\/(?<collection>[a-zA-Z0-9-.]+)(\/(?<rkey>[a-zA-Z0-9._~:@!$\&%'\)\(*+,;=-]+))?)?(#(?<fragment>\/[a-zA-Z0-9._~:@!$\&%'\)\(*+,;=\-[\]/\\]*))?$"#
        let regex = NSPredicate(format: "SELF MATCHES %@", aturiRegex)
        guard regex.evaluate(with: uri) else {
            throw AtUriError("ATURI didn't validate via regex")
        }
    }
}

// MARK: - Error Handling
struct AtUriError: Error, LocalizedError {
    private let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return message
    }
}
