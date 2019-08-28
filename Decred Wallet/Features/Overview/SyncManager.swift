//
//  SyncManager.swift
//  Decred Wallet
//
//  Created by Sprinthub on 27/08/2019.
//  Copyright © 2019 Decred. All rights reserved.
//

import Foundation
import Dcrlibwallet
import Signals

class SyncManager: NSObject {
    
    var netType: String?
    
    enum status{
        case complete
        case syncing
        case failed
        case waiting
    }
    
    var syncStatus = Signal<(status: status, error: String?)>()
    var peers = Signal<Int32>()

    override init() {
        super.init()
        self.netType = BuildConfig.IsTestNet ? "testnet" : BuildConfig.NetType
        
    }
    
    
    
}


extension SyncManager: SyncProgressListenerProtocol{
    func onStarted(_ wasRestarted: Bool) {
        self.syncStatus => (status: status.syncing, error: wasRestarted ? LocalizedStrings.restartingSynchronization : LocalizedStrings.startingSynchronization)
    }
    
    func onPeerConnectedOrDisconnected(_ numberOfConnectedPeers: Int32) {
        self.peers => numberOfConnectedPeers
    }
    
    func onHeadersFetchProgress(_ progressReport: DcrlibwalletHeadersFetchProgressReport) {
        
    }
    
    func onAddressDiscoveryProgress(_ progressReport: DcrlibwalletAddressDiscoveryProgressReport) {
        
    }
    
    func onHeadersRescanProgress(_ progressReport: DcrlibwalletHeadersRescanProgressReport) {
        var reportText = String(format: LocalizedStrings.latestBlock, AppDelegate.walletLoader.wallet!.getBestBlock())
        self.syncStatus => (status: status.syncing, error: reportText)
    }
    
    func onSyncCompleted() {
        self.syncStatus => (status: status.complete, nil)
    }
    
    func onSyncCanceled(_ willRestart: Bool) {
        self.syncStatus => (status: willRestart ? status.waiting : status.failed, error: willRestart ? LocalizedStrings.synchronizationError : LocalizedStrings.synchronizationCanceled)
    }
    
    func onSyncEndedWithError(_ error: String) {
        self.syncStatus => (status: status.failed, error: LocalizedStrings.synchronizationError)
    }
    
    func debug(_ debugInfo: DcrlibwalletDebugInfo) {
        //TODO: Probably wont be needed
    }
    
    
}

