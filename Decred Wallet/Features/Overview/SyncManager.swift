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

enum syncStatus{
    case complete
    case syncing
    case failed
    case waiting
}

class SyncManager{
    
//    static var shared = SyncManager()
    
    var netType: String?
    static var shared = SyncManager()
    
    let status: Signal = Signal<(status: syncStatus, error: String?)>()
    let peers: Signal = Signal<Int32>()

    init() {
//        super.init()
        self.netType = BuildConfig.IsTestNet ? "testnet" : BuildConfig.NetType
        
    }
}


extension SyncManager: SyncProgressListenerProtocol{
    func onStarted(_ wasRestarted: Bool) {
        status.fire((status: syncStatus.syncing, error: wasRestarted ? LocalizedStrings.restartingSynchronization : LocalizedStrings.startingSynchronization))
    }
    
    func onPeerConnectedOrDisconnected(_ numberOfConnectedPeers: Int32) {
        self.peers => numberOfConnectedPeers
    }
    
    func onHeadersFetchProgress(_ progressReport: DcrlibwalletHeadersFetchProgressReport) {
        
    }
    
    func onAddressDiscoveryProgress(_ progressReport: DcrlibwalletAddressDiscoveryProgressReport) {
        
    }
    
    func onHeadersRescanProgress(_ progressReport: DcrlibwalletHeadersRescanProgressReport) {
        let reportText = String(format: LocalizedStrings.latestBlock, AppDelegate.walletLoader.wallet!.getBestBlock())
//        self.status()
        self.status => (status: syncStatus.syncing, error: reportText)
    }
    
    func onSyncCompleted() {
        self.status => (status: syncStatus.complete, nil)
    }
    
    func onSyncCanceled(_ willRestart: Bool) {
        self.status => (status: willRestart ? syncStatus.waiting : syncStatus.failed, error: willRestart ? LocalizedStrings.synchronizationError : LocalizedStrings.synchronizationCanceled)
    }
    
    func onSyncEndedWithError(_ error: String) {
        self.status => (status: syncStatus.failed, error: LocalizedStrings.synchronizationError)
    }
    
    func debug(_ debugInfo: DcrlibwalletDebugInfo) {
        //TODO: Probably wont be needed
    }
    
    
}

