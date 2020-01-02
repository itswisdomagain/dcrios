//
//  WalletLoader.swift
//  Decred Wallet
//
// Copyright (c) 2018-2019 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

import Foundation
import Dcrlibwallet

class WalletLoader: NSObject {
    static let appDataDir = NSHomeDirectory() + "/Documents/dcrlibwallet"
    
    var multiWallet: DcrlibwalletMultiWallet!
    var syncer: Syncer
    var notification: TransactionNotification
    
    var isSynced: Bool {
        return self.syncer.currentSyncOp == SyncOp.Done
    }
    
    var oneOrMoreWalletsExist: Bool {
        return self.multiWallet.loadedWalletsCount() > 0
    }
    
    var wallet: DcrlibwalletWallet? {
        return multiWallet.defaultWallet()
    }
    
    override init() {
        syncer = Syncer()
        notification = TransactionNotification()
        super.init()
    }
    
    func initWallets() -> NSError? {
        var initWalletsError: NSError?
        self.multiWallet = DcrlibwalletNewMultiWallet(WalletLoader.appDataDir, "bdb", BuildConfig.NetType, &initWalletsError)
        return initWalletsError
    }
    
    func linkExistingWallet(startupPinOrPassword: String) {
        do {
            var privatePassphraseType = DcrlibwalletPassphraseTypePass
            if SpendingPinOrPassword.currentSecurityType() == SecurityViewController.SECURITY_TYPE_PIN {
                privatePassphraseType = DcrlibwalletPassphraseTypePin
            }
            
            try AppDelegate.walletLoader.multiWallet.linkExistingWallet(WalletLoader.appDataDir,
                                                                        originalPubPass: startupPinOrPassword,
                                                                        multiwalletPubPass: startupPinOrPassword,
                                                                        privatePassphraseType: privatePassphraseType)
        } catch let error {
            print("link existing wallet error: \(error.localizedDescription)")
        }
    }
    
}
