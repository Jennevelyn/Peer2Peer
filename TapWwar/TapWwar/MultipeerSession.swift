//
//  MultipeerSession.swift
//  TapWwar
//
//  Created by Jennifer Evelyn on 09/07/25.
//

import Foundation
import MultipeerConnectivity

class MultipeerSession: NSObject, ObservableObject {
    private let serviceType = "tapwar-game"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser

    @Published var peerTapCounts: [MCPeerID: Int] = [:]
    @Published var connectedPeers: [MCPeerID] = []

    override init() {
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self

        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func sendTapCount(_ count: Int) {
        let message: [String: Any] = [
            "name": myPeerID.displayName,
            "tap": count
        ]
        if let data = try? JSONSerialization.data(withJSONObject: message, options: []) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}

extension MultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let tap = json["tap"] as? Int {
            DispatchQueue.main.async {
                self.peerTapCounts[peerID] = tap
            }
        }
    }

    // Unused required methods
    func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
