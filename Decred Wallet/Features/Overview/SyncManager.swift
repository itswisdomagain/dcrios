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
    let newTransaction = Signal<Transaction>()
    let syncProgress = Signal<DcrlibwalletGeneralSyncProgress>()
    
    let syncStage = Signal<(Int, Any?)>()

    init() {
//        super.init()
        self.netType = BuildConfig.IsTestNet ? "testnet" : BuildConfig.NetType
        AppDelegate.walletLoader.notification.registerListener(for: "\(self)", newTxistener: self)
        AppDelegate.walletLoader.notification.registerListener(for: "\(self)", confirmedTxListener: self)
        
    }
}

extension SyncManager: NewTransactionNotificationProtocol, ConfirmedTransactionNotificationProtocol{
    func onTransaction(_ transaction: String?) {
        let tx = try! JSONDecoder().decode(Transaction.self, from:(transaction!.utf8Bits))
        self.newTransaction => tx
    }
    
    func onTransactionConfirmed(_ hash: String?, height: Int32) {
//        self.newTransaction =>
        //TODO: fire signal for transaction completion here for other views to act on
    }
    
    
}


extension SyncManager: SyncProgressListenerProtocol{
    func onStarted(_ wasRestarted: Bool) {
        self.status => (status: syncStatus.syncing, error: wasRestarted ? LocalizedStrings.restartingSynchronization : LocalizedStrings.startingSynchronization)
    }
    
    func onPeerConnectedOrDisconnected(_ numberOfConnectedPeers: Int32) {
        self.peers => numberOfConnectedPeers
    }
    
    func onHeadersFetchProgress(_ progressReport: DcrlibwalletHeadersFetchProgressReport) {
        let progress = Float(progressReport.headersFetchProgress) / 100.0
        
        self.syncStage => (1, String(format: LocalizedStrings.syncStageDescription, LocalizedStrings.fetchingBlockHeaders, progress))
    }
    
    func onAddressDiscoveryProgress(_ progressReport: DcrlibwalletAddressDiscoveryProgressReport) {
        self.syncProgress => progressReport.generalSyncProgress!
        self.syncStage => (2, LocalizedStrings.discoveringUsedAddresses)
    }
    
    func onHeadersRescanProgress(_ progressReport: DcrlibwalletHeadersRescanProgressReport) {
        let reportText = String(format: LocalizedStrings.latestBlock, AppDelegate.walletLoader.wallet!.getBestBlock())
        self.status => (status: syncStatus.syncing, error: reportText)
        if progressReport.generalSyncProgress == nil{
            return
        }else{
            self.syncProgress => progressReport.generalSyncProgress!
            self.syncStage => (3, nil)
        }
        
    }
    
    func onSyncCompleted() {
        self.status => (status: syncStatus.complete, nil)
    AppDelegate.walletLoader.syncer.deRegisterSyncProgressListener(for: "\(self)")
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

