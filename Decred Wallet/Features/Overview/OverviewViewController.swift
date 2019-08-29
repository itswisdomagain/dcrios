//
//  OverviewViewControllerr.swift
//  Decred Wallet
//
// Copyright (c) 2018-2019 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

import UIKit
//import Signals

class OverviewViewController: UIViewController {
//    @IBOutlet weak var syncProgressViewContainer: UIView!
//
//    @IBOutlet weak var overviewPageContentView: UIView!
//    @IBOutlet weak var fetchingBalanceIndicator: UIImageView!
//    @IBOutlet weak var recentTransactionsTableView: UITableView!
//
    // Stacked views (so we can add items if needed
    @IBOutlet weak var transactionHistorySection: UIStackView!
    @IBOutlet weak var walletStatusSection: UIStackView!
    
    // MARK: - Title Labels
    @IBOutlet weak var pageTitleLabel: UILabel!{
        didSet{
            self.pageTitleLabel.text = LocalizedStrings.overview
        }
    }
    
    @IBOutlet weak var currentBalance: UILabel!
    @IBOutlet weak var totalBalanceLabel: UILabel!{
        didSet{
            self.totalBalanceLabel.text = LocalizedStrings.currentTotalBalance
        }
    }
    
    // MARK: - Recent Transactions
    @IBOutlet weak var recentTransactionsLabelView: UIView!{
        didSet{
            self.recentTransactionsLabelView.horizontalBorder(borderColor: UIColor(red: 0.24, green: 0.35, blue: 0.45, alpha: 0.4), yPosition: self.recentTransactionsLabelView.frame.maxY-1, borderHeight: 0.52)
        }
        
    }
    @IBOutlet weak var recentTransactionsLabel: UILabel!{
        didSet{
            recentTransactionsLabel.text = LocalizedStrings.recentTransactions
        }
    }
    @IBOutlet var recentTransactionsTableView: UITableView!
    @IBOutlet weak var seeAllTransactionsButton: UIButton!{
        didSet{
            seeAllTransactionsButton.titleLabel?.text = LocalizedStrings.seeAll
            seeAllTransactionsButton.addBorder(atPosition: .top, color: UIColor(red: 0.24, green: 0.35, blue: 0.45, alpha: 0.4), thickness: 0.74)
        }
    }
    
    
    // Wallet status
    @IBOutlet weak var statusIndicator: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: Sync Status section setup
    @IBOutlet weak var walletStatusLabelView: UIView!
    @IBOutlet weak var walletStatusLabel: UILabel!
    
    @IBOutlet weak var onlineIndicator: UIView!
    @IBOutlet weak var onlineStatusLabel: UILabel!
    @IBOutlet weak var syncStatusIndicator: UIImageView!
    @IBOutlet weak var syncStatusLabel: UILabel!{
        didSet{
            syncStatusLabel.text = (AppDelegate.walletLoader.isSynced) ? LocalizedStrings.walletSynced : LocalizedStrings.walletNotSynced
        }
    }
    @IBOutlet weak var latestBlockLabel: UILabel!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    
    var recentTransactions = [Transaction]()
    var syncManager = SyncManager.shared
    var isSyncing: Bool = false
    
//    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//        if identifier == "embedSyncProgressVC" && AppDelegate.walletLoader.isSynced {
//            return false
//        }
//        return true
//    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "embedSyncProgressVC" {
//            (segue.destination as! SyncProgressViewController).afterSyncCompletes = self.initializeOverviewContent
//        }
//    }
    
    override func viewDidLoad() {
        self.setupInterface()
        
        syncManager.status.subscribe(with: self){ (status, error) in
//            let (status, error) = arg
            DispatchQueue.main.async {
                self.updateSync(status: status, error: error)
            }
        }
        
        syncManager.peers.subscribe(with: self){ (peers) in
            print(peers)
            DispatchQueue.main.async {
                let text = String(format: LocalizedStrings.connectedTo, peers)
                self.connectionStatusLabel.text! = text
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.96, alpha: 1)
        super.viewWillAppear(animated)
//        self.setupNavigationBar(withTitle: LocalizedStrings.overview)
    }
    
    func setupInterface(){
        walletStatusLabelView.horizontalBorder(borderColor: UIColor(red: 0.24, green: 0.35, blue: 0.45, alpha: 0.4), yPosition: recentTransactionsLabelView.frame.maxY-1, borderHeight: 0.32)
        walletStatusLabel.text = LocalizedStrings.walletStatus
        syncStatusIndicator.image = (AppDelegate.walletLoader.isSynced) ? UIImage(named: "icon-ok") : UIImage(named: "icon-cancel")
        syncStatusIndicator.contentMode = .scaleAspectFit
        
        latestBlockLabel.text = String(format: LocalizedStrings.latestBlock, (AppDelegate.walletLoader.wallet?.getBestBlock())!)
        
        
    }
    
    func updateRecentActivity(){
        let maxDisplayItems = round(self.recentTransactionsTableView.frame.size.height / TransactionTableViewCell.height())
        AppDelegate.walletLoader.wallet?.transactionHistory(count: Int32(maxDisplayItems)) { transactions in
            if transactions == nil || transactions!.count == 0 {
                self.showNoTransactions()
                return
            }

            self.recentTransactions = transactions!
            self.recentTransactionsTableView.backgroundView = nil
            self.recentTransactionsTableView.separatorStyle = .singleLine
            self.recentTransactionsTableView.reloadData()
        }
    }
    
    func updateSync(status: syncStatus, error: String?){
        switch status {
        case .complete:
//            do stuff
            if isSyncing{
                self.isSyncing = false
            }
            syncStatusLabel.text = (AppDelegate.walletLoader.isSynced) ? LocalizedStrings.walletSynced : LocalizedStrings.walletNotSynced
            syncStatusIndicator.image = (AppDelegate.walletLoader.isSynced) ? UIImage(named: "icon-ok") : UIImage(named: "icon-cancel")
            break
        case .failed:
//            do stuff again
            if self.isSyncing{
                self.isSyncing = false
            }
            self.syncStatusLabel.text = LocalizedStrings.syncError
        case .syncing:
//            do again
            if self.isSyncing{
                break
            }
            syncStatusLabel.text = LocalizedStrings.synchronizing
            syncStatusIndicator.image = UIImage(named: "icon-syncing")
            self.isSyncing = true
            break
        case .waiting:
//            do agaii
            if self.isSyncing{
                break
            }
            syncStatusLabel.text = LocalizedStrings.waitingToSync
            syncStatusIndicator.image = UIImage(named: "icon-syncing")
            self.isSyncing = true
            break
        }
    }
    
    
    
    func initializeOverviewContent() {
        self.updateRecentActivity()
//        self.syncProgressViewContainer.removeFromSuperview()
//        self.syncProgressViewContainer = nil
//
//        AppDelegate.walletLoader.notification.registerListener(for: "\(self)", newTxistener: self)
//        AppDelegate.walletLoader.notification.registerListener(for: "\(self)", confirmedTxListener: self)
//
//        self.fetchingBalanceIndicator.loadGif(name: "progress bar-1s-200px")
//        self.updateCurrentBalance()
//
//        self.recentTransactionsTableView.registerCellNib(TransactionTableViewCell.self)
//        self.recentTransactionsTableView.delegate = self
//        self.recentTransactionsTableView.dataSource = self
//        self.loadRecentActivity()
//
//        let pullToRefreshControl = UIRefreshControl()
//        pullToRefreshControl.addTarget(self, action: #selector(self.handleRecentActivityTableRefresh(_:)), for: UIControl.Event.valueChanged)
//        pullToRefreshControl.tintColor = UIColor.lightGray
//        self.recentTransactionsTableView.addSubview(pullToRefreshControl)
//
//        self.overviewPageContentView.isHidden = false
    }
    
    func updateCurrentBalance() {
//        DispatchQueue.main.async {
//            self.totalBalanceLabel.isHidden = true
//            self.fetchingBalanceIndicator.superview?.isHidden = false
//
//            let totalWalletAmount = AppDelegate.walletLoader.wallet?.totalWalletBalance()
//            let totalAmountRoundedOff = (Decimal(totalWalletAmount!) as NSDecimalNumber).round(8)
//
//            self.totalBalanceLabel.attributedText = Utils.getAttributedString(str: "\(totalAmountRoundedOff)", siz: 17.0, TexthexColor: GlobalConstants.Colors.TextAmount)
//            self.fetchingBalanceIndicator.superview?.isHidden = true
//            self.totalBalanceLabel.isHidden = false
//        }
    }
    
    @objc func handleRecentActivityTableRefresh(_ refreshControl: UIRefreshControl) {
        self.updateRecentActivity()
        refreshControl.endRefreshing()
    }
    
    
    func showNoTransactions() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.recentTransactionsTableView.bounds.size.width, height: self.recentTransactionsTableView.bounds.size.height))
        label.text = LocalizedStrings.noTransactions
        label.textAlignment = .center
        self.recentTransactionsTableView.backgroundView = label
        self.recentTransactionsTableView.separatorStyle = .none
    }
    
//    @IBAction func showAllTransactionsButtonTap(_ sender: Any) {
//        self.navigateToMenu(.history)
//    }
//
//    @IBAction func showSendPage(_ sender: Any) {
//        self.navigateToMenu(.send)
//    }
//
//    @IBAction func showReceivePage(_ sender: Any) {
//        self.navigateToMenu(.receive)
//    }
    
//    func navigateToMenu(_ menuItem: MenuItem) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
//            NavigationMenuController().changeActiveTab(to: menuItem)
//        }
//    }
}

extension OverviewViewController: NewTransactionNotificationProtocol, ConfirmedTransactionNotificationProtocol {
    func onTransaction(_ transaction: String?) {
//        var tx = try! JSONDecoder().decode(Transaction.self, from:(transaction!.utf8Bits))
//
//        if self.recentTransactions.contains(where: { $0.Hash == tx.Hash }) {
//            // duplicate notification, tx is already being displayed in table
//            return
//        }
//
//        tx.Animate = true
//        self.recentTransactions.insert(tx, at: 0)
//        self.updateCurrentBalance()
//
//        DispatchQueue.main.async {
//            let maxDisplayItems = round(self.recentTransactionsTableView.frame.size.height / TransactionTableViewCell.height())
//            if self.recentTransactions.count > Int(maxDisplayItems) {
//                _ = self.recentTransactions.popLast()
//            }
//
//            self.recentTransactionsTableView.reloadData()
//        }
    }
    
    func onTransactionConfirmed(_ hash: String?, height: Int32) {
        DispatchQueue.main.async {
//            self.updateCurrentBalance()
            self.updateRecentActivity()
        }
    }
}

extension OverviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionTableViewCell.height()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.recentTransactions.count == 0 {
            return
        }
        
        let txDetailsVC = Storyboards.TransactionFullDetailsViewController.instantiateViewController(for: TransactionFullDetailsViewController.self)
        txDetailsVC.transaction = self.recentTransactions[indexPath.row]
        self.navigationController?.pushViewController(txDetailsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.recentTransactions[indexPath.row].Animate {
            cell.blink()
        }
        self.recentTransactions[indexPath.row].Animate = false
    }
}

extension OverviewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recentTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.identifier) as! TransactionTableViewCell
        
        if self.recentTransactions.count != 0 {
            let tx = self.recentTransactions[indexPath.row]
            cell.setData(tx)
        }
        return cell
    }
}
