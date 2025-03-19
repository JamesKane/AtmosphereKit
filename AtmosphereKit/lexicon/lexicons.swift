//
//  lexicons.swift
//  AtmosphereKit
//
//  Created by James Kane on 3/19/25.
//

struct LexUserType: Codable {
    let type: String
    // Add other fields as necessary depending on what lexUserType is.
}

// Main struct to represent the schema
struct LexiconDoc: Codable {
    let lexicon: Int
    let id: String
    let revision: Int?
    let description: String?
    let defs: [String: LexUserType]
    
    // Custom validation method
    func validate() throws {
        // Ensure `lexicon` is always 1 (like `z.literal(1)`)
        guard lexicon == 1 else {
            throw ValidationError.invalidLexiconValue
        }
        
        // Ensure `id` is a valid NSID
        guard NSID.isValid(id) else {
            throw ValidationError.invalidNSID
        }
        
        // Iterate over definitions and validate the custom rule
        for (defId, def) in defs {
            if defId != "main" &&
                (def.type == "record" ||
                 def.type == "procedure" ||
                 def.type == "query" ||
                 def.type == "subscription") {
                throw ValidationError.invalidDefinition(defId: defId)
            }
        }
    }
    
    // Define domain-specific validation errors
    enum ValidationError: LocalizedError {
        case invalidLexiconValue
        case invalidNSID
        case invalidDefinition(defId: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidLexiconValue:
                return "Lexicon value must be 1."
            case .invalidNSID:
                return "Must be a valid NSID."
            case .invalidDefinition(let defId):
                return "Records, procedures, queries, and subscriptions must be the main definition (\(defId))."
            }
        }
    }
}
