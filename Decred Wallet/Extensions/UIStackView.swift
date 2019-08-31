//
//  UIStackView.swift
//  Decred Wallet
//
//  Created by Sprinthub on 30/08/2019.
//  Copyright © 2019 Decred. All rights reserved.
//

import UIKit

extension UIStackView {
    
    func cornerRadius(_ radius: CGFloat){
        let subView = UIView(frame: bounds)
        subView.backgroundColor = backgroundColor
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
        subView.translatesAutoresizingMaskIntoConstraints = true
        subView.layer.cornerRadius = 20
        subView.layer.masksToBounds = true
        subView.clipsToBounds = true
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
