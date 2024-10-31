// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SystemConfiguration
import Combine

public final class ConnectionManager: NSObject {
    public static var publisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }
    
    private static let subject = PassthroughSubject<Bool, Never>()

    private static var cancellables = Set<AnyCancellable>()
    private override init() {}
    
    @discardableResult
    private class func checkInternetConnectivity() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else {
            return false
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
    }
    
    public class func configure() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Self.subject.send(checkInternetConnectivity())
            }
            .store(in: &cancellables)
        
        print("🛜 Connection manager is set up!")
    }
    
}
