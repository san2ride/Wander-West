//
//  ShopDetailViewController.swift
//  w in the W
//
//  Created by don't touch me on 3/23/17.
//  Copyright © 2017 trvl, LLC. All rights reserved.
//

import UIKit

class ShopDetailViewController: UIViewController {

    @IBOutlet weak var shopImageView: UIImageView!
    var shopImageURL: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shopImageView.imageFromServer(urlString: shopImageURL!)
    }
}
