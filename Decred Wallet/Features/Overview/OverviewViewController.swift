//
//  OverviewViewControllerr.swift
//  Decred Wallet
//
// Copyright (c) 2018-2019 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

import UIKit

class OverviewViewController: UIViewController {
    // Stacked views (so we can add items if needed)
    @IBOutlet weak var transactionHistorySection: UIStackView!{
        didSet{
            transactionHistorySection.layer.backgroundColor = UIColor.white.cgColor
            transactionHistorySection.cornerRadius(15)
        }
    }
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
            seeAllTransactionsButton.isHidden = (recentTransactions.count < 3) ? true : false
            seeAllTransactionsButton.titleLabel?.text = LocalizedStrings.seeAll
            seeAllTransactionsButton.addBorder(atPosition: .top, color: UIColor(red: 0.24, green: 0.35, blue: 0.45, alpha: 0.4), thickness: 0.74)
        }
    }
    
    
    // Wallet status
//    @IBOutlet weak var statusIndicator: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: Sync Status section setup
    @IBOutlet weak var walletStatusLabelView: UIView!
    @IBOutlet weak var syncStatusView: UIView!
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
    
    
    var recentTransactions = [Transaction](){
        didSet{
            if self.recentTransactions.count > 3{
                self.seeAllTransactionsButton.isHidden = false
            }
        }
    }
    var syncManager = SyncManager.shared
    var isSyncing: Bool = false{
        didSet{
            if self.isSyncing{
                self.showSyncStatus()
            }
        }
    }
    
    var syncToggle: Bool = false{
        didSet{
            if !syncToggle{
                self.hideSyncStatus()
            }
        }
    }
    
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
        
        if AppDelegate.walletLoader.isSynced{
            self.updateRecentActivity()
        }else{
            self.showNoTransactions()
        }
        
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
        
        syncManager.newTransaction.subscribe(with: self){ (tx) in
            if self.recentTransactions.contains(where: { $0.Hash == tx.Hash }) {
                // duplicate notification, tx is already being displayed in table
                return
            }
            DispatchQueue.main.async {
                self.updateCurrentBalance()
                self.updateRecentActivity()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.96, alpha: 1)
        super.viewWillAppear(animated)
    }
    
    func setupInterface(){
        walletStatusLabelView.horizontalBorder(borderColor: UIColor(red: 0.24, green: 0.35, blue: 0.45, alpha: 0.4), yPosition: recentTransactionsLabelView.frame.maxY-1, borderHeight: 0.32)
        walletStatusLabel.text = LocalizedStrings.walletStatus
        syncStatusIndicator.image = (AppDelegate.walletLoader.isSynced) ? UIImage(named: "icon-ok") : UIImage(named: "icon-cancel")
        syncStatusIndicator.contentMode = .scaleAspectFit
        
        latestBlockLabel.text = String(format: LocalizedStrings.latestBlock, (AppDelegate.walletLoader.wallet?.getBestBlock())!)
        
        onlineIndicator.layer.cornerRadius = 5
        onlineIndicator.layer.backgroundColor = ((AppDelegate.walletLoader.wallet?.walletOpened())!) ? UIColor.appColors.decredGreen.cgColor : UIColor.red.cgColor
        
        // show transactions button action
        seeAllTransactionsButton.addTarget(self, action: #selector(self.handleShowAllTransactions), for: .touchUpInside)
        
        let pullToRefreshControl = UIRefreshControl()
        pullToRefreshControl.addTarget(self, action: #selector(self.handleRecentActivityTableRefresh(_:)), for: UIControl.Event.valueChanged)
        pullToRefreshControl.tintColor = UIColor.lightGray
        self.recentTransactionsTableView.addSubview(pullToRefreshControl)
        
        
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
            if isSyncing{
                self.isSyncing = false
            }
            syncStatusLabel.text = (AppDelegate.walletLoader.isSynced) ? LocalizedStrings.walletSynced : LocalizedStrings.walletNotSynced
            syncStatusIndicator.image = (AppDelegate.walletLoader.isSynced) ? UIImage(named: "icon-ok") : UIImage(named: "icon-cancel")
            self.hideSyncStatus()
            break
        case .failed:
            if self.isSyncing{
                self.isSyncing = false
            }
            self.syncStatusLabel.text = LocalizedStrings.syncError
        case .syncing:
            if self.isSyncing{
                break
            }
            syncStatusLabel.text = LocalizedStrings.synchronizing
            syncStatusIndicator.image = UIImage(named: "icon-syncing")
            self.isSyncing = true
            break
        case .waiting:
            if self.isSyncing{
                break
            }
            syncStatusLabel.text = LocalizedStrings.waitingToSync
            syncStatusIndicator.image = UIImage(named: "icon-syncing")
            self.isSyncing = true
            break
        }
    }
    
    func showSyncStatus(){
        self.onlineIndicator.layer.backgroundColor = UIColor.appColors.decredGreen.cgColor
        self.onlineStatusLabel.text = LocalizedStrings.online
        self.walletStatusSection.frame = CGRect(x: walletStatusSection.frame.minX, y: walletStatusSection.frame.minY, width: walletStatusSection.frame.size.width, height: 196)
        
        UIView.animate(withDuration: 0.2){
            self.latestBlockLabel.isHidden = true
            self.connectionStatusLabel.isHidden = true
        }
        
        //Progressbar
        let syncProgress = UIProgressView(frame: CGRect.zero)
        syncProgress.layer.cornerRadius = 4
        syncProgress.clipsToBounds = true
        syncProgress.progressTintColor = UIColor.init(hex: "#41be53")
        // Progress percentage
        let percentage = UILabel(frame: CGRect.zero)
        percentage.font = UIFont(name: "Source Sans Pro", size: 16.0)
        percentage.clipsToBounds = true
        // Time left
        let timeLeft = UILabel(frame: CGRect.zero)
        timeLeft.font = UIFont(name: "Source Sans Pro", size: 16.0)
        timeLeft.clipsToBounds = true
        // See sync details buttons
        let showDetailsButton = UIButton(frame: CGRect(x: 0, y: 0, width: syncStatusView.frame.size.width, height: 48))
        showDetailsButton.clipsToBounds = true
        showDetailsButton.titleLabel!.font = UIFont(name: "Source Sans Pro", size: 16.0)
        showDetailsButton.backgroundColor = UIColor.white
        showDetailsButton.setTitle(LocalizedStrings.showDetails, for: .normal)
        showDetailsButton.setTitleColor(UIColor.appColors.decredBlue, for: .normal)
        showDetailsButton.addBorder(atPosition: .top, color: UIColor.appColors.lightGray, thickness: 0.4)
        showDetailsButton.addTarget(self, action: #selector(self.handleShowSyncDetails), for: .touchUpInside)
        
        self.walletStatusSection.addSubview(syncProgress)
        self.walletStatusSection.addSubview(percentage)
        self.walletStatusSection.addSubview(timeLeft)
        self.walletStatusSection.addArrangedSubview(showDetailsButton)
        
        syncProgress.translatesAutoresizingMaskIntoConstraints = false
        timeLeft.translatesAutoresizingMaskIntoConstraints = false
        percentage.translatesAutoresizingMaskIntoConstraints = false
        showDetailsButton.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            syncProgress.heightAnchor.constraint(equalToConstant: 8.0),
            syncProgress.widthAnchor.constraint(equalToConstant: 272.0),
            syncProgress.leadingAnchor.constraint(equalTo: self.syncStatusLabel.leadingAnchor),
            syncProgress.topAnchor.constraint(equalTo: self.syncStatusLabel.bottomAnchor, constant: 16),
            percentage.heightAnchor.constraint(equalToConstant: 16),
            percentage.leadingAnchor.constraint(equalTo: self.syncStatusLabel.leadingAnchor),
            percentage.topAnchor.constraint(equalTo: syncProgress.bottomAnchor, constant: 8),
            timeLeft.heightAnchor.constraint(equalToConstant: 16),
            timeLeft.trailingAnchor.constraint(equalTo: self.walletStatusSection.trailingAnchor, constant: -31),
            timeLeft.topAnchor.constraint(equalTo: syncProgress.bottomAnchor, constant: 8),
            showDetailsButton.heightAnchor.constraint(equalToConstant: 48),
            showDetailsButton.widthAnchor.constraint(equalToConstant: syncStatusView.frame.width),
            showDetailsButton.bottomAnchor.constraint(equalTo: walletStatusSection.bottomAnchor),
            showDetailsButton.leadingAnchor.constraint(equalTo: syncStatusView.leadingAnchor),
            showDetailsButton.trailingAnchor.constraint(equalTo: syncStatusView.trailingAnchor),
            
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        // Listen for sync progress changes and react to them
        syncManager.syncProgress.subscribe(with: self){ (progressReport) in
            timeLeft.text = String(format: LocalizedStrings.syncTimeLeft, progressReport.totalTimeRemaining)
            percentage.text = String(format: LocalizedStrings.syncProgressComplete, progressReport.totalSyncProgress)
            syncProgress.progress = Float(progressReport.totalSyncProgress) / 100.0
        }
    }
    
    func hideSyncStatus(){
//        self.walletStatusSection.frame = CGRect(x: walletStatusSection.frame.minX, y: walletStatusSection.frame.minY, width: walletStatusSection.frame.size.width, height: 162)
        UIView.animate(withDuration: 2.0){
            self.walletStatusSection.subviews.forEach({$0.removeFromSuperview()})
            self.latestBlockLabel.isHidden = false
            self.connectionStatusLabel.isHidden = false
        }
        
    }
    
    func updateCurrentBalance() {
        DispatchQueue.main.async {
            let totalWalletAmount = AppDelegate.walletLoader.wallet?.totalWalletBalance()
            let totalAmountRoundedOff = (Decimal(totalWalletAmount!) as NSDecimalNumber).round(8)
            self.currentBalance.attributedText = Utils.getAttributedString(str: "\(totalAmountRoundedOff)", siz: 17.0, TexthexColor: GlobalConstants.Colors.TextAmount)
        }
    }
    
    @objc func handleRecentActivityTableRefresh(_ refreshControl: UIRefreshControl) {
        self.updateRecentActivity()
        refreshControl.endRefreshing()
    }
    
    @objc func handleShowAllTransactions(){
        DispatchQueue.main.async {
            self.tabBarController?.selectedIndex = 1
        }
    }
    
    @objc func handleShowSyncDetails(){
//        index(before i: Int)
        let syncDetailsComponent = self.syncDetailsComponent()
        let position = self.walletStatusSection.arrangedSubviews.index(before: self.walletStatusSection.arrangedSubviews.endIndex)
        UIView.animate(withDuration: 4.3){
            self.walletStatusSection.insertArrangedSubview(syncDetailsComponent.0, at: position)
            syncDetailsComponent.0.topAnchor.constraint(equalTo: self.syncStatusView.bottomAnchor).isActive = true
            syncDetailsComponent.0.heightAnchor.constraint(equalToConstant: 188.0).isActive = true
            NSLayoutConstraint.activate(syncDetailsComponent.1)
        }
    }
    
    @objc func handleHideSyncDetails(){
//        index(before i: Int)
    }
    
    
    func syncDetailsComponent() -> (UIView, [NSLayoutConstraint]){
        // containing view for details
        let detailsContainerView = UIView(frame: CGRect.zero)
        detailsContainerView.layer.backgroundColor = UIColor.white.cgColor
        
        // Components for syncdetails view
        var stepLabel = UILabel(frame: CGRect.zero)
        var blockProgressLabel = UILabel(frame: CGRect.zero)
        
        // Inner component holding full details
        var detailsView = UIView(frame: CGRect.zero)
        var stepsLabel = UILabel(frame: CGRect.zero)
        var stepDetailLabel = UILabel(frame: CGRect.zero)
        var headersFetchedCount = UILabel(frame: CGRect.zero)
        var syncProgressLabel = UILabel(frame: CGRect.zero)
        var syncProgressCount = UILabel(frame: CGRect.zero)
        var connectedPeersLabel = UILabel(frame: CGRect.zero)
        var connectedPeerCount = UILabel(frame: CGRect.zero)
        
        stepsLabel.font = UIFont(name: "Source Sans Pro", size: 14)
        stepLabel.text = String(format: LocalizedStrings.syncSteps, 0)
        
        stepDetailLabel.font = UIFont(name: "Source Sans Pro", size: 14)
        stepDetailLabel.text = ""
//        stepLabel.sizeToFit()
        
        detailsContainerView.addSubview(stepLabel)
        detailsContainerView.addSubview(stepDetailLabel)
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        stepDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        let constraints = [
            detailsContainerView.heightAnchor.constraint(equalToConstant: 188),
            stepLabel.heightAnchor.constraint(equalToConstant: 14),
            stepLabel.topAnchor.constraint(equalTo: detailsContainerView.topAnchor, constant: -21),
            stepLabel.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor, constant: 16),
            stepDetailLabel.topAnchor.constraint(equalTo: detailsContainerView.topAnchor, constant: -20),
            stepDetailLabel.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor, constant: -16),
        ]
        
        
        syncManager.syncStage.subscribe(with: self){ (stage, reporText) in
            
            stepLabel.text = String(format: LocalizedStrings.syncSteps, stage)
            
            if reporText != nil{
                stepDetailLabel.text = reporText as? String
            }
        }
        
        return (detailsContainerView, constraints)
//        stepsLabel.text = String(format: LocalizedStrings, 0, 0)
    }
    
    func showNoTransactions() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.recentTransactionsTableView.bounds.size.width, height: self.recentTransactionsTableView.bounds.size.height))
        label.text = LocalizedStrings.noTransactions
        label.textAlignment = .center
        self.recentTransactionsTableView.backgroundView = label
        self.recentTransactionsTableView.separatorStyle = .none
    }
    
}
//
//extension OverviewViewController: NewTransactionNotificationProtocol, ConfirmedTransactionNotificationProtocol {
//    func onTransaction(_ transaction: String?) {
////
////
////        if self.recentTransactions.contains(where: { $0.Hash == tx.Hash }) {
////            // duplicate notification, tx is already being displayed in table
////            return
////        }
////
////        tx.Animate = true
////        self.recentTransactions.insert(tx, at: 0)
////        self.updateCurrentBalance()
////
////        DispatchQueue.main.async {
////            let maxDisplayItems = round(self.recentTransactionsTableView.frame.size.height / TransactionTableViewCell.height())
////            if self.recentTransactions.count > Int(maxDisplayItems) {
////                _ = self.recentTransactions.popLast()
////            }
////
////            self.recentTransactionsTableView.reloadData()
////        }
//    }
//
//    func onTransactionConfirmed(_ hash: String?, height: Int32) {
//        DispatchQueue.main.async {
//            self.updateCurrentBalance()
//            self.updateRecentActivity()
//        }
//    }
//}

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
