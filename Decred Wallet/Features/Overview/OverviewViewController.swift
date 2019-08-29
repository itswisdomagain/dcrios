//
//  OverviewViewControllerr.swift
//  Decred Wallet
//
// Copyright (c) 2018-2019 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

import UIKit
import Signals

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
    @IBOutlet weak var statusIndicator: UIImageView!{
        didSet{
            self.syncStatusIndicator.image = (AppDelegate.walletLoader.isSynced) ? UIImage(named: "icon-ok") : UIImage(named: "icon-cancel")
            self.statusIndicator.contentMode = .scaleAspectFit
        }
    }
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: Sync Status section setup
    @IBOutlet weak var walletStatusLabelView: UIView!{
        didSet{
            walletStatusLabelView.horizontalBorder(borderColor: UIColor(red: 0.24, green: 0.35, blue: 0.45, alpha: 0.4), yPosition: recentTransactionsLabelView.frame.maxY-1, borderHeight: 0.52)
        }
    }
    @IBOutlet weak var walletStatusLabel: UILabel!{
        didSet{
            walletStatusLabel.text = LocalizedStrings.walletStatus
        }
    }
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
    var syncManager = SyncManager()
    
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
        if AppDelegate.walletLoader.isSynced {
            self.initializeOverviewContent()
        }
        
        self.syncManager.syncStatus.subscribe(with: self){ (arg) in
            
            let (status, error) = arg
            self.updateSync(status: status, error: error)
        }
        
        self.syncManager.peers.subscribe(with: self){ arg in
            print("Peers: \(arg)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.setupNavigationBar(withTitle: LocalizedStrings.overview)
    }
    
    func setupInterface(){
        // Container view setup
        view.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.96, alpha: 1)
        
        
        // MARK: Floating buttons setup
//        buttonView.layer.cornerRadius = 24
//        let separator = UIView(frame: CGRect.zero)
//        separator.backgroundColor = UIColor.white
//        separator.isOpaque = true
////        separator.clipsToBounds = true
//        buttonView.addSubview(separator)
//        buttonView.bringSubviewToFront(separator)
////        separator.translatesAutoresizingMaskIntoConstraints = true
//        separator.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
//        separator.widthAnchor.constraint(equalToConstant: 2.0)
//        separator.centerXAnchor.constraint(equalTo: buttonView.centerXAnchor).isActive = true
//        
//
//
//
//
//
//        
//        
//        
//
//
//
//
//        receiveButton.titleLabel?.text = LocalizedStrings.receive
        
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
    
    func updateSync(status: SyncManager.status, error: String?){
        if error == nil{
            
            return
        }
        
        switch status {
        case .complete:
//            do stuff
            break
        case .failed:
//            do stuff again
            break
        case .syncing:
//            do again
            break
        case .waiting:
//            do agaii
            break
        default:
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
