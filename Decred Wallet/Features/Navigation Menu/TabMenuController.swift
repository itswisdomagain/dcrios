//
//  TabMenuController.swift
//  Decred Wallet
//
//  Created by Sprinthub on 26/08/2019.
//  Copyright © 2019 Decred. All rights reserved.
//

import UIKit

enum TabItems: String, CaseIterable{
    case overview = "Overview"
    case transactions = "Transactions"
    case accounts = "Accounts"
    case more = "More"
    
    var viewController: UIViewController{
        switch self {
        case .overview:
            return Storyboards.Overview.instantiateViewController(for: OverviewViewController.self).wrapInNavigationcontroller()
        case .transactions:
            return TransactionHistoryViewController().wrapInNavigationcontroller()
        case .accounts:
            return Storyboards.Accounts.instantiateViewController(for: AccountsViewController.self).wrapInNavigationcontroller()
        case .more:
            return Storyboards.More.instantiateViewController(for: MoreViewController.self).wrapInNavigationcontroller()
        }
    }
}

class TabMenuController: UITabBarController{
    
    var bar: TabMenu!
    fileprivate lazy var defaultTabBarHeight = { tabBar.frame.size.height }()
    
    var controllers = [UIViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        tabBar.isHidden = true
    }
    
    public func setupCustomTabBar(_ withItems: [TabBarItem], completion: @escaping ([UIViewController]) -> Void){
        
        let frame = tabBar.frame
        
        bar = TabMenu(items: withItems, frame: frame)
        bar.clipsToBounds = true
        view.addSubview(bar)
        
        bar.translatesAutoresizingMaskIntoConstraints = true
        NSLayoutConstraint.activate([
            bar.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            bar.rightAnchor.constraint(equalTo: view.rightAnchor),
            bar.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
        
        for i in 0 ..< withItems.count{
            controllers.append(withItems[i].controller!)
        }
        self.view.layoutIfNeeded()
        completion(controllers)
    }
    
    
    
}


class TabMenu: UIView{
    
    public var font: UIFont? {
        didSet {
            for itv in self.itemViews {
                itv.font = self.font!
            }
        }
    }
    
    fileprivate let bg = UIView()
    
    fileprivate var itemViews = [TabBarItemView]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    convenience init(items: [TabBarItem], frame: CGRect) {
        self.init(frame: frame)
        bg.backgroundColor = UIColor.white.withAlphaComponent(1)
        addSubview(bg)
       
        for i in 0 ..< items.count{
            let itemView = TabBarItemView(items[i], index: i)
            self.itemViews.append(itemView)
            self.addSubview(itemView)
            print("Item \(i) \(items[i])")
        }
    }
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        bg.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 1000)
        
        let itemWidth = self.frame.width / CGFloat(self.itemViews.count)
        for (i, itemView) in self.itemViews.enumerated() {
            let x = itemWidth * CGFloat(i)
            itemView.frame = CGRect(x: x, y: 0, width: itemWidth, height: 70)
        }
    }
    
    func changeActiveTab(from: Int, to: Int){
        
    }
}
