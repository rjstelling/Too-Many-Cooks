//
//  Receiver.swift
//  TMCLANKit
//
//  Created by Richard Stelling on 03/12/2019.
//  Copyright © 2019 Richard Stelling. All rights reserved.
//

import Foundation

extension Notification.Name {
    public static let TMCDiscoveredLANGame = Notification.Name("TMCDiscoveredLANGame")
    public static let TMCRemovedLANGame = Notification.Name("TMCRemovedLANGame")
}

// MARK: - Receiver

private class Resolver: NSObject, NetServiceDelegate {
    
    let receiver: Receiver
    
    init(receiver: Receiver) {
        self.receiver = receiver
        super.init()
    }
}

private class ResolveDescovered: Resolver {
        
    func netServiceDidResolveAddress(_ sender: NetService) {
        
        guard let data = sender.txtRecordData() else { return }
        let gameInfo = NetService.dictionary(fromTXTRecord: data)

        guard let identifierData = gameInfo[TXTRecord.identifier.rawValue], let identifier = String(bytes: identifierData, encoding: .utf8) else { return }
        guard let nameData = gameInfo[TXTRecord.name.rawValue], let name = String(bytes: nameData, encoding: .utf8) else { return }
        guard let platformData = gameInfo[TXTRecord.platform.rawValue], let platform = String(bytes: platformData, encoding: .utf8) else { return }
        
        // This is not my game
        guard self.receiver.localIdentifier?.uuidString != identifier else { return }
                
        let info = GameInfo(name: name, identifier: identifier, platform: platform)
        self.receiver.addGame(info, sender)
    }
}

private class ResolveRemoved: Resolver {
        
    func netServiceDidResolveAddress(_ sender: NetService) {
        
        guard let data = sender.txtRecordData() else { return }
        let gameInfo = NetService.dictionary(fromTXTRecord: data)

        guard let identifierData = gameInfo[TXTRecord.identifier.rawValue], let identifier = String(bytes: identifierData, encoding: .utf8) else { return }
        guard let nameData = gameInfo[TXTRecord.name.rawValue], let name = String(bytes: nameData, encoding: .utf8) else { return }
        guard let platformData = gameInfo[TXTRecord.platform.rawValue], let platform = String(bytes: platformData, encoding: .utf8) else { return }
        
        let info = GameInfo(name: name, identifier: identifier, platform: platform)
        self.receiver.removeGame(info, sender)
    }
}

internal class Receiver: NSObject, NetServiceBrowserDelegate {
        
    private let netServiceBrowser = NetServiceBrowser()
    private var discoveredNetService: [NetService] = []
    
    public private(set) var resolvedGames: [String : GameInfo] = [:]
    
    private static let name: String = ""
    private static let type: String = "_toomanycooks._tcp."
    private static let port: Int32 = 2424
    
    private let queue = DispatchQueue(label: "internal.ReceiverAccess.queue")
    
    internal var delegate: ReceiverDelegate?
    //private var callBack: ServiceFoundClosure?
    
    internal var localIdentifier: UUID?
    
    deinit {
        self.stop()
    }
    
    internal override init() {
        super.init()
        
        //self.callBack = callBack
        
        self.netServiceBrowser.delegate = self
    }
    
    internal func addGame(_ game: GameInfo, _ service: NetService) {
        
        queue.sync {
            // This is a new game
            guard !self.resolvedGames.contains( where: { $0.key == game.identifier }) else { return }
            self.resolvedGames[game.identifier] = game
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .TMCDiscoveredLANGame, object: self, userInfo: self.resolvedGames)
            }
        }
        
        self.discoveredNetService.removeAll { $0 == service }
        
        print("[DEBUG] Service count: \(self.discoveredNetService.count)")
    }
    
    internal func removeGame(_ game: GameInfo, _ service: NetService) {
    
        queue.sync {
            
            self.resolvedGames[game.identifier] = nil
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .TMCDiscoveredLANGame, object: self, userInfo: self.resolvedGames)
            }
        }
        
        self.discoveredNetService.removeAll { $0 == service }
        
        print("[DEBUG] Service count: \(self.discoveredNetService.count)")
    }
    
    func search() {
        self.netServiceBrowser.searchForServices(ofType: Receiver.type, inDomain: "")
    }
    
    func stop() {
        self.netServiceBrowser.stop()
    }
    
    // MARK: - NetServiceBrowserDelegate
    
    private lazy var resolverDiscovered = ResolveDescovered(receiver: self)
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        guard service.type == Receiver.type else { return }
        
        self.discoveredNetService.append(service)
        
        service.delegate = resolverDiscovered
        service.resolve(withTimeout: 20)
    }
    
    private lazy var resolverRemoved = ResolveRemoved(receiver: self)
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
                
        guard service.type == Receiver.type else { return }
        
        self.discoveredNetService.append(service)
        
        service.delegate = resolverRemoved
        service.resolve(withTimeout: 20)

//        guard let data = service.txtRecordData() else { return }
//        let gameInfo = NetService.dictionary(fromTXTRecord: data)
//
//        guard let identifierData = gameInfo[TXTRecord.identifier.rawValue], let identifier = String(bytes: identifierData, encoding: .utf8) else { return }
////        guard let nameData = gameInfo[TXTRecord.name.rawValue], let name = String(bytes: nameData, encoding: .utf8) else { return }
////        guard let platformData = gameInfo[TXTRecord.platform.rawValue], let platform = String(bytes: platformData, encoding: .utf8) else { return }
//
//        self.resolvedGames[identifier] = nil
//
//        NotificationCenter.default.post(name: .TMCRemovedLANGame, object: self, userInfo: self.resolvedGames)
    }
    
    /*func netServiceDidResolveAddress(_ sender: NetService) {
        
        guard let data = sender.txtRecordData() else { return }
        
        let gameInfo = NetService.dictionary(fromTXTRecord: data)
        
        if let name = String(bytes: gameInfo["GAME_NAME"] ?? Data(), encoding: .utf8), let identifier = String(bytes: gameInfo["GAME_ID"] ?? Data(), encoding: .utf8) {
            
            print("GAME ID: \(name)")
            print("GAME NMAE: \(identifier)")
            gameName = name
            gameId = identifier
            
            DispatchQueue.main.async {
                self.playJoin.setTitle("Join \(name)", for: .normal)
            }
        }
        
    }*/
}
