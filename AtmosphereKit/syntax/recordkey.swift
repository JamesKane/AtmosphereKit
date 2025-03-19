//
//  recordkey.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

// Custom Error for Invalid Record Key
struct InvalidRecordKeyError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

// Utility for Record Key Validation
struct RecordKeyValidator {
    
    // MARK: - Validation Methods
    
    static func ensureValidRecordKey(_ rkey: String) throws {
        // Validate length
        let length = rkey.count
        if length < 1 || length > 512 {
            throw InvalidRecordKeyError(message: "Record key must be 1 to 512 characters")
        }
        
        // Validate using the regex
        let validRegex = #"^[a-zA-Z0-9_~.:-]{1,512}$"#
        if !rkey.matches(regex: validRegex) {
            throw InvalidRecordKeyError(message: "Record key syntax not valid (regex)")
        }
        
        // Check for invalid keys ('.' or '..')
        if rkey == "." || rkey == ".." {
            throw InvalidRecordKeyError(message: "Record key cannot be \".\" or \"..\"")
        }
    }
    
    static func isValidRecordKey(_ rkey: String) -> Bool {
        do {
            try ensureValidRecordKey(rkey)
            return true
        } catch is InvalidRecordKeyError {
            return false
        } catch {
            // Re-throw any unexpected errors
            fatalError("Unexpected error: \(error)")
        }
    }
}
