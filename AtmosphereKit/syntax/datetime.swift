//
//  datetime.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

import Foundation

// Custom Error for Invalid Datetime
struct InvalidDatetimeError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

// DateTime Utility
struct DateTimeValidator {
    
    // MARK: - Validation Methods
    
    // Ensures the datetime string is valid according to the rules
    static func ensureValidDatetime(_ dtStr: String) throws {
        // Try parsing the string into a date
        guard let date = ISO8601DateFormatter().date(from: dtStr) else {
            throw InvalidDatetimeError(message: "Datetime did not parse as ISO 8601")
        }
        
        // Check if the normalized datetime is negative (forbidden)
        let isoStr = ISO8601DateFormatter().string(from: date)
        if isoStr.starts(with: "-") {
            throw InvalidDatetimeError(message: "Datetime normalized to a negative time")
        }
        
        // Regex check for RFC-3339 compliance
        let regex = #"^[0-9]{4}-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-6][0-9]:[0-6][0-9](\.[0-9]{1,20})?(Z|([+-][0-2][0-9]:[0-5][0-9]))$"#
        if !dtStr.matches(regex: regex) {
            throw InvalidDatetimeError(message: "Datetime didn't validate via regex")
        }
        
        // Check the length constraint
        if dtStr.count > 64 {
            throw InvalidDatetimeError(message: "Datetime is too long (64 chars max)")
        }
        
        // Disallow "-00:00" for UTC timezone
        if dtStr.hasSuffix("-00:00") {
            throw InvalidDatetimeError(message: "Datetime cannot use \"-00:00\" for UTC timezone")
        }
        
        // Disallow year zero or extremely early dates
        if dtStr.starts(with: "000") {
            throw InvalidDatetimeError(message: "Datetime so close to year zero is not allowed")
        }
    }
    
    // Returns true if the datetime string is valid, false otherwise
    static func isValidDatetime(_ dtStr: String) -> Bool {
        do {
            try ensureValidDatetime(dtStr)
            return true
        } catch is InvalidDatetimeError {
            return false
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Normalization Methods
    
    // Normalizes a valid or somewhat-valid datetime string to a consistent ISO-8601 format
    static func normalizeDatetime(_ dtStr: String) throws -> String {
        // If the datetime is already valid
        if isValidDatetime(dtStr) {
            let isoStr = ISO8601DateFormatter().string(from: ISO8601DateFormatter().date(from: dtStr)!)
            if isValidDatetime(isoStr) {
                return isoStr
            }
        }

        // Check if the string is missing a timezone and append 'Z' for UTC
        let timezoneRegex = #".*(([+-]\d\d:?\d\d)|[a-zA-Z])$"#
        if !dtStr.matches(regex: timezoneRegex) {
            if let date = ISO8601DateFormatter().date(from: dtStr + "Z") {
                let tzStr = ISO8601DateFormatter().string(from: date)
                if isValidDatetime(tzStr) {
                    return tzStr
                }
            }
        }

        // Parse any remaining datetime as a date and normalize
        if let date = ISO8601DateFormatter().date(from: dtStr) {
            let isoStr = ISO8601DateFormatter().string(from: date)
            if isValidDatetime(isoStr) {
                return isoStr
            } else {
                throw InvalidDatetimeError(message: "Datetime normalized to invalid timestamp string")
            }
        }

        // Input could not be parsed as any valid datetime
        throw InvalidDatetimeError(message: "Datetime did not parse as any valid format")
    }
    
    // Variant of normalizeDatetime() that guarantees a valid output (returns UNIX epoch time on error)
    static func normalizeDatetimeAlways(_ dtStr: String) -> String {
        do {
            return try normalizeDatetime(dtStr)
        } catch is InvalidDatetimeError {
            return ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: 0)) // UNIX epoch: 1970-01-01T00:00:00.000Z
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }
}
