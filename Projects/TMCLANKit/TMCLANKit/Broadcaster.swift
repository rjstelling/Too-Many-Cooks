//
//  Broadcaster.swift
//  TMCLANKit
//
//  Created by Richard Stelling on 03/12/2019.
//  Copyright © 2019 Richard Stelling. All rights reserved.
//

import Foundation

// MARK: - Broadcaster

internal class Broadcaster {
    
    internal enum Error: Swift.Error {
        case failedEncoding(String)
        case serviceRunning
        case failedToCreateService
    }
    
    private var netService: NetService?
    
    public private(set) var gameName: String?
    public private(set) var gameIdentifier: UUID?
    
    private static let name: String = ""
    private static let type: String = "_toomanycooks._tcp."
    private static let port: Int32 = 2424
    
    deinit {
        self.stop()
    }
    
    internal func create(_ gameName: String, identifier gameId: UUID) throws {
        
        guard self.netService == nil else { throw Error.serviceRunning }
        
        self.gameName = gameName
        self.gameIdentifier = gameId
        
        guard let nameData = gameName.data(using: .utf8) else { throw Error.failedEncoding(gameName) }
        guard let identifierData = gameId.uuidString.data(using: .utf8) else { throw Error.failedEncoding(gameId.uuidString) }
        guard let platformData = "iOS".data(using: .utf8) else { throw Error.failedEncoding("iOS") }
        
        self.netService = NetService(domain: "local.",
                                     type: Broadcaster.type,
                                     name: Broadcaster.name,
                                     port: Broadcaster.port)
        
        assert(self.netService != nil, "Failed to create Net Service object")
        
        let data = NetService.data(fromTXTRecord: [TXTRecord.identifier.rawValue : identifierData,
                                                   TXTRecord.name.rawValue : nameData,
                                                   TXTRecord.platform.rawValue : platformData])
        
        guard self.netService!.setTXTRecord(data) else { throw Error.failedToCreateService }
        self.netService?.publish()
    }
    
    /// Stop bradcasting the game id
    internal func stop() {
        self.netService?.stop()
        self.netService = nil
        self.gameName = nil
        self.gameIdentifier = nil
    }
}
