import Foundation

struct ChallengeResponse: Decodable {
    let device_id: String
    let challenge: String
    let expires_in: Int
}

struct LicenceResponse: Decodable {
    let device_id: String
    let product: String
    let entitlement: String
    let license: String
}

struct LicenceSummary: Codable, Equatable {
    let deviceID: String
    let entitlement: String
    let envelope: String
    let cachedAt: Date
}

struct LicencePlan: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let priceDisplay: String
    let description: String
}

struct LicenceAccountStatus: Codable, Equatable {
    let deviceID: String
    let ownership: String
    let entitlement: String
    let planID: String?
    let planName: String?
    let transferable: Bool
}

enum LicenceAppError: LocalizedError {
    case invalidURL
    case service(String)
    case transferUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The licence service URL is invalid."
        case .service(let message): return message
        case .transferUnavailable: return "No EFIS local transfer transport is configured yet."
        }
    }
}
