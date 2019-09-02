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
            self.recentTransactionsLabelView.horizontalBorder(borderColor: UIColor(red: 0.24, green: 0.35, blue: 0.45, alpha: 0.4), yPosition: self.recentTransactionsLabelView.frame.maxY-2, borderHeight: 0.52)
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
    @IBOutlet weak var showSyncStatusButton: UIButton!{
        didSet{
            if !isSyncing{
                self.showSyncStatusButton.isHidden = true
            }
        }
    }
    
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
                self.showSyncStatusButton.isHidden = false
            }else{
                self.hideSyncStatus()
                self.showSyncStatusButton.isHidden = true
            }
        }
    }
    
    var syncToggle: Bool = false{
        didSet{
            if syncToggle{
                handleShowSyncDetails()
            }else{
                handleHideSyncDetails()
            }
        }
    }
    
    override func viewDidLoad() {
        self.setupInterface()
        self.updateCurrentBalance()
        if AppDelegate.walletLoader.isSynced{
            self.updateRecentActivity()
        }else{
            self.showNoTransactions()
        }
        
        syncManager.status.subscribe(with: self){ (status, error) in
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        DispatchQueue.main.async {
            self.transactionHistorySection.layer.backgroundColor = UIColor.white.cgColor
            self.transactionHistorySection.cornerRadius(18)
            
            self.walletStatusSection.layer.backgroundColor = UIColor.white.cgColor
            self.walletStatusSection.cornerRadius(18)
        }
    }
    // preliminary setup of overview interface
    func setupInterface(){
        walletStatusLabel.text = LocalizedStrings.walletStatus
        syncStatusIndicator.image = (AppDelegate.walletLoader.isSynced) ? UIImage(named: "icon-ok") : UIImage(named: "icon-cancel")
        syncStatusIndicator.contentMode = .scaleAspectFit
        
        latestBlockLabel.text = String(format: LocalizedStrings.latestBlock, (AppDelegate.walletLoader.wallet?.getBestBlock())!)
        
        // Fix this to show internet connection status instead
        onlineIndicator.layer.cornerRadius = 5
        onlineIndicator.layer.backgroundColor = ((AppDelegate.walletLoader.wallet?.walletOpened())!) ? UIColor.appColors.decredGreen.cgColor : UIColor.red.cgColor
        
        // show transactions button action
        seeAllTransactionsButton.addTarget(self, action: #selector(self.handleShowAllTransactions), for: .touchUpInside)

        showSyncStatusButton.titleLabel!.font = UIFont(name: "Source Sans Pro", size: 16.0)
        showSyncStatusButton.setTitle(LocalizedStrings.showDetails, for: .normal)
        showSyncStatusButton.setTitleColor(UIColor.appColors.decredBlue, for: .normal)
        showSyncStatusButton.addBorder(atPosition: .top, color: UIColor.appColors.lightGray, thickness: 0.5)
        showSyncStatusButton.addTarget(self, action: #selector(self.handleShowSyncToggle), for: .touchUpInside)
        
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
            self.handleHideSyncDetails()
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
    // Show sync status progress bar
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
        
        self.walletStatusSection.addSubview(syncProgress)
        self.walletStatusSection.addSubview(percentage)
        self.walletStatusSection.addSubview(timeLeft)
        
        syncProgress.translatesAutoresizingMaskIntoConstraints = false
        timeLeft.translatesAutoresizingMaskIntoConstraints = false
        percentage.translatesAutoresizingMaskIntoConstraints = false

        
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
            
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        // Listen for sync progress changes and react to them
        syncManager.syncProgress.subscribe(with: self){ (progressReport) in
            timeLeft.text = String(format: LocalizedStrings.syncTimeLeft, progressReport.totalTimeRemaining)
            percentage.text = String(format: LocalizedStrings.syncProgressComplete, progressReport.totalSyncProgress)
            syncProgress.progress = Float(progressReport.totalSyncProgress) / 100.0
        }
    }
    // hide sync status progressbar and time
    func hideSyncStatus(){
        if self.walletStatusSection.subviews.count > 3{
            UIView.animate(withDuration: 2.0){
                for i in 3 ..< 4{
                    self.walletStatusSection.subviews[i].removeFromSuperview()
                }
                self.latestBlockLabel.isHidden = false
                self.connectionStatusLabel.isHidden = false
            }
        }

        let blockAge = self.setBestBlockAge()
        let bestBlock = AppDelegate.walletLoader.wallet!.getBestBlock()
        self.latestBlockLabel.text = String(format: LocalizedStrings.latestBlockAge, bestBlock, blockAge)
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
    
    @objc func handleShowSyncToggle(){
        if self.syncToggle{
            self.syncToggle = false
        }else{
            self.syncToggle = true
        }
    }
    
    // Show sync details on user click "show details" button while syncing
    func handleShowSyncDetails(){
        let syncDetailsComponent = self.syncDetailsComponent()
        let position = self.walletStatusSection.arrangedSubviews.index(before: self.walletStatusSection.arrangedSubviews.endIndex)
        UIView.animate(withDuration: 4.3){
            self.walletStatusSection.insertArrangedSubview(syncDetailsComponent.view, at: position)
            syncDetailsComponent.view.topAnchor.constraint(equalTo: self.syncStatusView.bottomAnchor).isActive = true
            syncDetailsComponent.view.heightAnchor.constraint(equalToConstant: 188.0).isActive = true
            NSLayoutConstraint.activate(syncDetailsComponent.constraints)
        }
        showSyncStatusButton.setTitle(LocalizedStrings.hideDetails, for: .normal)
    }
    // Hide sync details on "hide details" button click or on sync completion
    func handleHideSyncDetails(){
        if self.walletStatusSection.arrangedSubviews.indices.contains(2){
            UIView.animate(withDuration: 4.3){
                self.walletStatusSection.arrangedSubviews[2].removeFromSuperview()
            }
        }
        showSyncStatusButton.setTitle(LocalizedStrings.showDetails, for: .normal)
    }
    
    // Sync details view
    func syncDetailsComponent() -> (view: UIView, constraints: [NSLayoutConstraint]){
        // containing view for details
        let detailsContainerView = UIView(frame: CGRect.zero)
        detailsContainerView.layer.backgroundColor = UIColor.white.cgColor
        
        // Inner component holding full details
        let detailsView = UIView(frame: CGRect.zero), stepsLabel = UILabel(frame: CGRect.zero), stepDetailLabel = UILabel(frame: CGRect.zero), headersFetchedLabel = UILabel(frame: CGRect.zero), headersFetchedCount = UILabel(frame: CGRect.zero), syncProgressLabel = UILabel(frame: CGRect.zero), syncProgressCount = UILabel(frame: CGRect.zero), connectedPeersLabel = UILabel(frame: CGRect.zero), connectedPeerCount = UILabel(frame: CGRect.zero)
        
        stepsLabel.font = UIFont(name: "Source Sans Pro", size: 13)
        stepsLabel.text = String(format: LocalizedStrings.syncSteps, 0)
        
        stepDetailLabel.font = UIFont(name: "Source Sans Pro", size: 14)
        stepDetailLabel.text = ""
        
        detailsView.layer.backgroundColor = UIColor.init(hex: "#f3f5f6").cgColor
        detailsView.layer.cornerRadius = 8
        // fetched headers text
        headersFetchedLabel.font = UIFont(name: "Source Sans Pro", size: 14)
        headersFetchedLabel.text = LocalizedStrings.blockHeadersFetched
        headersFetchedLabel.translatesAutoresizingMaskIntoConstraints = false
        // Fetched headers count
        headersFetchedCount.font = UIFont(name: "Source Sans Pro", size: 14)
        headersFetchedCount.text = ""
        headersFetchedCount.translatesAutoresizingMaskIntoConstraints = false
        headersFetchedCount.clipsToBounds = true
        
        // Syncing progress text
        syncProgressLabel.font = UIFont(name: "Source Sans Pro", size: 14)
        syncProgressLabel.text = LocalizedStrings.syncingProgress
        syncProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // block age behind
        syncProgressCount.font = UIFont(name: "Source Sans Pro", size: 14)
        syncProgressCount.text = ""
        syncProgressCount.translatesAutoresizingMaskIntoConstraints = false
        syncProgressCount.clipsToBounds = true
        
        // Connected peers
        connectedPeersLabel.font = UIFont(name: "Source Sans Pro", size: 14)
        connectedPeersLabel.text = LocalizedStrings.connectedPeersCount
        connectedPeersLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // show connected peers count
        connectedPeerCount.font = UIFont(name: "Source Sans Pro", size: 14)
        connectedPeerCount.text = "0"
        connectedPeerCount.translatesAutoresizingMaskIntoConstraints = false
        
        // Add them  to the detailsview
        detailsView.addSubview(headersFetchedLabel)
        detailsView.addSubview(headersFetchedCount) // %headersFetched% of %total haeader%
        detailsView.addSubview(syncProgressLabel) // SYncing progress
        detailsView.addSubview(syncProgressCount) // days behind count
        detailsView.addSubview(connectedPeersLabel) // Connected peers count label
        detailsView.addSubview(connectedPeerCount) // number of connected peers
        
        // Add all components to superview
        detailsContainerView.addSubview(stepsLabel)
        detailsContainerView.addSubview(stepDetailLabel)
        detailsContainerView.addSubview(detailsView)
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false
        stepDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsView.translatesAutoresizingMaskIntoConstraints = false
        
        
        let constraints = [
            detailsContainerView.heightAnchor.constraint(equalToConstant: 120),
            stepsLabel.heightAnchor.constraint(equalToConstant: 14),
            stepsLabel.topAnchor.constraint(equalTo: detailsContainerView.topAnchor, constant: -21),
            stepsLabel.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor, constant: 16),
            stepDetailLabel.topAnchor.constraint(equalTo: detailsContainerView.topAnchor, constant: -20),
            stepDetailLabel.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor, constant: -16),
            stepDetailLabel.heightAnchor.constraint(equalToConstant: 16),
            
            detailsView.heightAnchor.constraint(equalToConstant: 100),
            detailsView.topAnchor.constraint(equalTo: stepDetailLabel.bottomAnchor, constant: 20.0),
            detailsView.bottomAnchor.constraint(equalTo: detailsContainerView.bottomAnchor, constant: -20),
            detailsView.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor, constant: 16),
            detailsView.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor, constant: -16),
            
            headersFetchedLabel.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: 16),
            headersFetchedLabel.topAnchor.constraint(equalTo: detailsView.topAnchor, constant: 17),
            headersFetchedLabel.heightAnchor.constraint(equalToConstant: 16),
            headersFetchedCount.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor, constant: -16),
            headersFetchedCount.topAnchor.constraint(equalTo: detailsView.topAnchor, constant: 17),
            headersFetchedCount.heightAnchor.constraint(equalTo: headersFetchedLabel.heightAnchor),
            
            syncProgressLabel.heightAnchor.constraint(equalToConstant: 16),
            syncProgressLabel.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: 16),
            syncProgressLabel.topAnchor.constraint(equalTo: headersFetchedLabel.bottomAnchor, constant: 18),
            syncProgressCount.topAnchor.constraint(equalTo: headersFetchedCount.bottomAnchor, constant: 16),
            syncProgressCount.heightAnchor.constraint(equalToConstant: 16),
            syncProgressCount.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor, constant: -16),
            
            connectedPeersLabel.heightAnchor.constraint(equalToConstant: 16),
            connectedPeersLabel.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: 16),
            connectedPeersLabel.topAnchor.constraint(equalTo: syncProgressLabel.bottomAnchor, constant: 18),
            connectedPeerCount.topAnchor.constraint(equalTo: syncProgressCount.bottomAnchor, constant: 16),
            connectedPeerCount.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor, constant: -16),
            connectedPeerCount.heightAnchor.constraint(equalToConstant: 15),
        ]
        
        syncManager.syncStage.subscribe(with: self){ (stage, reporText) in
            stepsLabel.text = String(format: LocalizedStrings.syncSteps, stage)
            
            if reporText != nil{
                stepDetailLabel.text = reporText as? String
            }
        }
        
        syncManager.headerFetchProgress.subscribe(with: self){ (progressReport) in
            headersFetchedCount.text = String(format: LocalizedStrings.fetchedHeaders, progressReport.fetchedHeadersCount, progressReport.totalHeadersToFetch)
            headersFetchedCount.sizeToFit()
            if progressReport.bestBlockAge != "" {
                syncProgressCount.text = String(format: LocalizedStrings.bestBlockAgebehind, progressReport.bestBlockAge)
                syncProgressCount.sizeToFit()
            }
        }
        
        syncManager.peers.subscribe(with: self){ (peers) in
            connectedPeerCount.text = String(peers)
        }
        return (detailsContainerView, constraints)
    }
    
    func showNoTransactions() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.recentTransactionsTableView.bounds.size.width, height: self.recentTransactionsTableView.bounds.size.height))
        label.text = LocalizedStrings.noTransactions
        label.textAlignment = .center
        self.recentTransactionsTableView.backgroundView = label
        self.recentTransactionsTableView.separatorStyle = .none
    }
    
    func setBestBlockAge() -> String {
        if AppDelegate.walletLoader.wallet!.isScanning() {
            return ""
        }
        
        let bestBlockAge = Int64(Date().timeIntervalSince1970) - AppDelegate.walletLoader.wallet!.getBestBlockTimeStamp()
        
        switch bestBlockAge {
        case Int64.min...0:
            return LocalizedStrings.now
            
        case 0..<Utils.TimeInSeconds.Minute:
            return String(format: LocalizedStrings.secondsAgo, bestBlockAge)
            
        case Utils.TimeInSeconds.Minute..<Utils.TimeInSeconds.Hour:
            let minutes = bestBlockAge / Utils.TimeInSeconds.Minute
            return String(format: LocalizedStrings.minAgo, minutes)
            
        case Utils.TimeInSeconds.Hour..<Utils.TimeInSeconds.Day:
            let hours = bestBlockAge / Utils.TimeInSeconds.Hour
            return String(format: LocalizedStrings.hrsAgo, hours)
            
        case Utils.TimeInSeconds.Day..<Utils.TimeInSeconds.Week:
            let days = bestBlockAge / Utils.TimeInSeconds.Day
            return String(format: LocalizedStrings.daysAgo, days)
            
        case Utils.TimeInSeconds.Week..<Utils.TimeInSeconds.Month:
            let weeks = bestBlockAge / Utils.TimeInSeconds.Week
            return String(format: LocalizedStrings.weeksAgo, weeks)
            
        case Utils.TimeInSeconds.Month..<Utils.TimeInSeconds.Year:
            let months = bestBlockAge / Utils.TimeInSeconds.Month
            return String(format: LocalizedStrings.monthsAgo, months)
            
        default:
            let years = bestBlockAge / Utils.TimeInSeconds.Year
            return String(format: LocalizedStrings.yearsAgo, years)
        }
    }
    
}
// Recent transactions
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
