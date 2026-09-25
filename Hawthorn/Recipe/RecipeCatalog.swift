import Foundation

/// Bundled bottles and recipes. The log never copies this catalog.
enum RecipeCatalog {
    struct Document: Codable, Equatable, Sendable {
        let schemaVersion: Int
        let bottles: [Bottle]
        let recipes: [Recipe]
    }

    static func load(from data: Data) -> Result<Document, CatalogError> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let envelope: SchemaEnvelope
        do {
            envelope = try decoder.decode(SchemaEnvelope.self, from: data)
        } catch {
            return .failure(.malformed)
        }
        switch envelope.schemaVersion {
        case 1:
            do {
                let document = try decoder.decode(Document.self, from: data)
                return .success(document)
            } catch {
                return .failure(.malformed)
            }
        default:
            return .failure(.unsupportedSchema)
        }
    }

    private struct SchemaEnvelope: Decodable {
        let schemaVersion: Int
    }
}

enum CatalogError: Equatable, Error, Sendable {
    case malformed
    case unsupportedSchema
}
