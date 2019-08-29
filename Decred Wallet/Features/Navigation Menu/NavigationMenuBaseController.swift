//
//  NavigationMenuViewController.swift
//  Decred Wallet
//
// Copyright (c) 2018-2019 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.
import UIKit
import Dcrlibwallet

class NavigationMenuBaseController: TabMenuController{
    
    var isNewWallet: Bool = false
    var restartSyncTriggered: Bool = false

    var syncManager = SyncManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.createFloatingButton()
        
        if self.isNewWallet{
            showNewWalletAlert(completion: self.checkNetworkConnectionForSync)
        }else{
            self.checkNetworkConnectionForSync()
        }
    }
    
    // MARK: View controllers setup for tab bar
    func setupView(){
        
        let overview = Storyboards.Overview.instantiateViewController(for: OverviewViewController.self).wrapInNavigationcontroller()
        overview.tabBarItem.image = UIImage(named: "menu/overview")
        overview.tabBarItem.title = LocalizedStrings.overview
        
        let transactions = TransactionHistoryViewController()
        transactions.tabBarItem.image = UIImage(named: "menu/transactions")
        transactions.tabBarItem.title = LocalizedStrings.transactions
        
        let accounts = Storyboards.Accounts.instantiateViewController(for: AccountsViewController.self).wrapInNavigationcontroller()
        accounts.tabBarItem.image = UIImage(named: "accounts")
        accounts.tabBarItem.title = LocalizedStrings.accounts
        
        let more = Storyboards.More.instantiateViewController(for: MoreViewController.self).wrapInNavigationcontroller()
        more.tabBarItem.image = UIImage(named: "menu")
        more.tabBarItem.title = LocalizedStrings.more
        
        viewControllers = [overview, transactions, accounts, more]
        tabBar.backgroundColor = UIColor.white
        self.selectedIndex = 0
    }
    
    func createFloatingButton(){
        // Floating buttons containing view
        let floatingView = UIView(frame: CGRect.zero)
        floatingView.layer.cornerRadius = 24
        floatingView.backgroundColor = UIColor.init(hex: "#2970ff")
        
        self.view.addSubview(floatingView)
        floatingView.translatesAutoresizingMaskIntoConstraints = false
        floatingView.clipsToBounds = true
        
        // Separator
        let separator = UIView(frame: CGRect.zero)
        separator.backgroundColor = UIColor.white
        separator.clipsToBounds = true
        floatingView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonFont = UIFont(name: "Source Sans Pro", size: 16)
        // Send button
        let sendButton = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 48))
        sendButton.setTitle(LocalizedStrings.send, for: .normal)
        sendButton.setTitleColor(UIColor.white, for: .normal)
        sendButton.setImage(UIImage(named: "ic_send_24px"), for: .normal)
        sendButton.titleLabel?.font = buttonFont
        sendButton.imageView?.contentMode = .scaleAspectFill
        sendButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 31)
        sendButton.titleEdgeInsets = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 15)
        sendButton.contentVerticalAlignment = .fill
        sendButton.contentHorizontalAlignment = .fill
        floatingView.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.clipsToBounds = true
        
        // Receive button
        let receiveButton = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 48))
        receiveButton.setImage(UIImage(named: "ic_receive_24px"), for: .normal)
        receiveButton.setTitleColor(UIColor.white, for: .normal)
        receiveButton.setTitle(LocalizedStrings.receive, for: .normal)
        receiveButton.titleLabel?.font = buttonFont
        receiveButton.contentVerticalAlignment = .fill
        receiveButton.contentHorizontalAlignment = .fill
        receiveButton.imageView?.contentMode = .scaleAspectFill
        receiveButton.titleEdgeInsets = UIEdgeInsets(top: 15, left: 25, bottom: 15, right: -15)
        receiveButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 10)
        floatingView.addSubview(receiveButton)
        receiveButton.clipsToBounds = true
        receiveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            floatingView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0.0),
            floatingView.widthAnchor.constraint(equalToConstant: 240),
            floatingView.heightAnchor.constraint(equalToConstant: 48),
            floatingView.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -12),
            separator.heightAnchor.constraint(equalToConstant: 24),
            separator.widthAnchor.constraint(equalToConstant: 1.0),
            separator.centerXAnchor.constraint(equalTo: floatingView.centerXAnchor),
            separator.centerYAnchor.constraint(equalTo: floatingView.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 48),
            sendButton.widthAnchor.constraint(equalToConstant: 90),
            sendButton.bottomAnchor.constraint(equalTo: floatingView.bottomAnchor, constant: 0),
            sendButton.topAnchor.constraint(equalTo: floatingView.topAnchor, constant: 0),
            sendButton.leadingAnchor.constraint(equalTo: floatingView.leadingAnchor, constant: 25),
            receiveButton.trailingAnchor.constraint(equalTo: floatingView.trailingAnchor, constant: -25),
            receiveButton.topAnchor.constraint(equalTo: floatingView.topAnchor, constant: 0),
            receiveButton.bottomAnchor.constraint(equalTo: floatingView.bottomAnchor, constant: 0),
            receiveButton.widthAnchor.constraint(equalToConstant: 90),
            receiveButton.heightAnchor.constraint(equalToConstant: 48),
        ]
        NSLayoutConstraint.activate(constraints)
        
    }
    
    static func setupMenuAndLaunchApp(isNewWallet: Bool){
        // wallet is open, setup sync listener and start notification listener
        AppDelegate.walletLoader.syncer.registerEstimatedSyncProgressListener()
        AppDelegate.walletLoader.notification.startListeningForNotifications()
        
        let startView = NavigationMenuBaseController()
        startView.isNewWallet = isNewWallet
        AppDelegate.shared.setAndDisplayRootViewController(startView)
        
    }
    
    
    func checkSyncPermission() {
        if AppDelegate.shared.reachability.connection == .none {
            self.syncNotStartedDueToNetwork()
        } else if AppDelegate.shared.reachability.connection == .wifi || Settings.syncOnCellular {
            self.startSync()
        } else {
            self.requestPermissionToSync()
        }
    }
    
    func checkNetworkConnectionForSync() {
        // Re-trigger app network change listener to ensure correct network status is determined.
        AppDelegate.shared.listenForNetworkChanges()
        
        if AppDelegate.shared.reachability.connection == .none {
            self.showOkAlert(message: LocalizedStrings.cannotSyncWithoutNetworkConnection, title: LocalizedStrings.internetConnectionRequired, onPressOk: self.checkSyncPermission)
        } else {
            self.checkSyncPermission()
        }
    }
    
    func syncNotStartedDueToNetwork() {
        AppDelegate.walletLoader.syncer.deRegisterSyncProgressListener(for: "\(self)")
        AppDelegate.walletLoader.wallet?.cancelSync()
        
        // Allow 0.5 seconds for sync cancellation to complete before setting up wallet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppDelegate.walletLoader.syncer.assumeSyncCompleted()
//            self.onSyncCompleted()
            
//            self.syncStatusLabel.text = LocalizedStrings.connectToWiFiToSync
//            self.syncStatusLabel.superview?.backgroundColor = UIColor.red
        }
    }
    
    func requestPermissionToSync() {
        let permission = UIAlertController(title: "Sync Now?", message: LocalizedStrings.notConnectedToWiFi, preferredStyle: .alert)
        let denyAction = UIAlertAction(title: LocalizedStrings.notNow, style: .default, handler: { (action) in
            self.syncNotStartedDueToNetwork()
        })
        let allowAction = UIAlertAction(title: LocalizedStrings.allowOnce, style: .default, handler: { (action) in
            self.startSync()
        })
        let alwaysAllowAction = UIAlertAction(title: LocalizedStrings.always, style: .default, handler: {(action) in
            Settings.setValue(true, for: Settings.Keys.SyncOnCellular)
            self.startSync()
        })
        
        permission.addAction(allowAction)
        permission.addAction(alwaysAllowAction)
        permission.addAction(denyAction)
        self.present(permission, animated: true)
    }
    
    
    func startSync(){
        AppDelegate.walletLoader.syncer.registerSyncProgressListener(for: "\(self)", syncManager)
        
        if self.restartSyncTriggered {
            self.restartSyncTriggered = false
            self.restartSync()
        } else {
//            self.resetSyncViews()
            AppDelegate.walletLoader.syncer.beginSync()
        }
    }
    
    
    func restartSync() {
        AppDelegate.walletLoader.syncer.restartSync()
        
//        self.stopRefreshingBestBlockAge()
        
//        self.resetSyncViews()
//        self.syncStatusLabel.text = LocalizedStrings.restartingSync
    }
    
    // Show a temporary "wallet created" alert if this is a new wallet
    func showNewWalletAlert(completion: @escaping (() -> Void)){
        let label =  UILabel(frame: CGRect(x: 129, y: 128, width: 117, height: 32))
        label.textAlignment = .center
        label.backgroundColor = UIColor.appColors.decredGreen
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = LocalizedStrings.walletCreated
        label.textColor = UIColor.white
        label.layer.cornerRadius = 7
        
        UIView.animate(withDuration: 4.0){
            self.view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = true
            label.clipsToBounds = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4){
            UIView.animate(withDuration: 3.0){
                label.removeFromSuperview()
            }
        }
        completion()
    }
}

//
//extension NavigationMenuController: UITabBarDelegate{
//
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
////        if viewController.isKind(of: ActionViewController.self) {
////            let vc =  ActionViewController()
////            vc.modalPresentationStyle = .overFullScreen
////            self.present(vc, animated: true, completion: nil)
////            return false
////        }
//        return true
//    }
//}
