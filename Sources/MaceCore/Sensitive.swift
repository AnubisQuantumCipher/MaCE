import Foundation
#if os(Darwin)
import Darwin
#else
import Glibc
#endif

public final class SensitiveData {
    public private(set) var data: Data
    public init(_ data: Data) { self.data = data }
    deinit { zero() }
    public func zero() {
        #if os(Darwin)
        data.withUnsafeMutableBytes { if let b = $0.baseAddress { explicit_bzero(b, $0.count) } }
        #else
        data.withUnsafeMutableBytes { if let b = $0.baseAddress { memset(b, 0, $0.count) } }
        #endif
    }
}


