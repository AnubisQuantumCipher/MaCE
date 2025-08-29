import Foundation

public enum MaceError: Error, CustomStringConvertible, Sendable {
    case notFound, badKey(String), crypto(String), parse(String), mac, overflow, misuse(String), io(String)
    public var description: String {
        switch self {
        case .notFound: return "Not found"
        case .badKey(let s): return "Bad key: \(s)"
        case .crypto(let s): return "Crypto error: \(s)"
        case .parse(let s): return "Parse error: \(s)"
        case .mac: return "MAC verification failed"
        case .overflow: return "Counter overflow"
        case .misuse(let s): return "Misuse: \(s)"
        case .io(let s): return "I/O error: \(s)"
        }
    }
}


