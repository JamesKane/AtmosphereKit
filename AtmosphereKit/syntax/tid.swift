//
//  tid.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

// Constant values for TID
private let TID_LENGTH = 13
private let TID_REGEX = "^[234567abcdefghij][234567abcdefghijklmnopqrstuvwxyz]{12}$"

// Custom Error for Invalid TIDs
struct InvalidTidError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

// Utility for TID validation
struct TidValidator {
    
    // Ensures the TID is valid according to length and regex rules
    static func ensureValidTid(_ tid: String) throws {
        // Check length
        if tid.count != TID_LENGTH {
            throw InvalidTidError(message: "TID must be \(TID_LENGTH) characters")
        }
        
        // Check against regex
        if !tid.matches(regex: TID_REGEX) {
            throw InvalidTidError(message: "TID syntax not valid (regex)")
        }
    }
    
    // Checks if the TID is valid (returns true/false, no error throwing)
    static func isValidTid(_ tid: String) -> Bool {
        return tid.count == TID_LENGTH && tid.matches(regex: TID_REGEX)
    }
}
