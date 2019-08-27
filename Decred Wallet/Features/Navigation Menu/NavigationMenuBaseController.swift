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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        if self.isNewWallet{
            showNewWalletAlert()
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
    
    
    // Show a temporary "wallet created" alert if this is a new wallet
    func showNewWalletAlert(){
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
    }
    
//    func changeActiveTab(to: MenuItem){
//        self.selectedIndex = to.rawValue
//    }
//
    
    static func setupMenuAndLaunchApp(isNewWallet: Bool){
        // wallet is open, setup sync listener and start notification listener
        AppDelegate.walletLoader.syncer.registerEstimatedSyncProgressListener()
        AppDelegate.walletLoader.notification.startListeningForNotifications()
        
        let startView = NavigationMenuBaseController()
        startView.isNewWallet = isNewWallet
        AppDelegate.shared.setAndDisplayRootViewController(startView)
        
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
