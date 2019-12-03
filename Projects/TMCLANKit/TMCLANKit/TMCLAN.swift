//
//  TMCLAN.swift
//  TMCLANKit
//
//  Created by Richard Stelling on 03/12/2019.
//  Copyright © 2019 Richard Stelling. All rights reserved.
//

import Foundation

internal enum TXTRecord: String {
    case identifier = "GAME_ID"
    case name = "GAME_NAME"
    case platform = "HOSTING_PLATFORM"
}

public protocol TMCLANDelegate {
    func gameDscovered()
}

public struct GameInfo {
    public let name: String
    public let identifier: String
    public let platform: String
}

private typealias ServiceFoundClosure = (GameInfo) -> () //name, id

protocol ReceiverDelegate {
    func discoveredGame()
    func removedGame()
}

public struct TMCLAN {
    
//    internal enum Error: Swift.Error {
//        case failedUUIDGeneration
//        case failedNameGeneration
//    }
    
    public private(set) static var shared = TMCLAN()
    
    private let broadcaster = Broadcaster()
    private let receiver = Receiver()
    
    public var gameName: String? { self.broadcaster.gameName }
    public var gameIdentifier: UUID? { self.broadcaster.gameIdentifier }
    
    public var delegate: TMCLANDelegate?
    
    private init() {
//        self.receiver = Receiver { [self] in
//            print("\($0.name) -> \($0.identifier)")
//            self.delegate?.gameDscovered()
//        }
        
        self.receiver.delegate = self
        
    }
    
    public func broadcast(gameName name: String) throws {
    
        self.broadcaster.stop()
        
        let identifier = UUID()
        self.receiver.localIdentifier = identifier
        try self.broadcaster.create(name, identifier: identifier)
    }
    
    public func stopBroadcast() {
        self.receiver.localIdentifier = nil
        self.broadcaster.stop()
    }

    public func search() {
        
//        _ = self.receiver.observe(\Receiver.resolvedGames) { (receiver, keyValue) in
//            print("\(receiver)")
//            print("\(keyValue)")
//        }
        
        self.receiver.search()
    }
    
    public func stopSearch() {
        self.receiver.stop()
    }
}

extension TMCLAN: ReceiverDelegate {
    func discoveredGame() { self.delegate?.gameDscovered() }
    func removedGame() {}
}
