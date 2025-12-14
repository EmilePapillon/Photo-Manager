import Foundation

struct Keyword: Identifiable, Hashable {
    let id = UUID()
    var name: String
}

struct AITag: Identifiable, Hashable {
    let id = UUID()
    var provider: AIProvider
    var labels: [String]
    var caption: String
    var confidence: Double
    var timestamp: Date
}

struct Embedding: Hashable {
    var provider: AIProvider
    var vector: [Float]
}

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI
    case azure
    case google
    case appleVision
    case localCLIP

    var id: String { rawValue }

    var isCloud: Bool {
        switch self {
        case .openAI, .azure, .google:
            return true
        case .appleVision, .localCLIP:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .azure: return "Azure Vision"
        case .google: return "Google Vision"
        case .appleVision: return "Apple Vision"
        case .localCLIP: return "Local CLIP"
        }
    }
}
