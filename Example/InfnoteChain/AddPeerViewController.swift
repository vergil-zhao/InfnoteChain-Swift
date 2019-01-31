//
//  AddPeerViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/10/22.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import InfnoteChain

class AddPeerViewController: UITableViewController {

    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var rankField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func addButtonTouched(_ sender: Any) {
        guard let address = addressField.text,
            let peer = Peer(address: address) else {
            return
        }
        PeerManager.shared.addOrUpdate(peer)
        navigationController?.popViewController(animated: true)
    }
}
