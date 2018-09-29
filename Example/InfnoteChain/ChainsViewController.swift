//
//  ChainsViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/9/29.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import InfnoteChain

class ChainsViewController: UITableViewController {
    
    let manager = ChainManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.allChains.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let chain = manager.allChains[indexPath.row].chain
        if let info = chain.info, let name = info["name"] as? String {
            cell.textLabel?.text = name
        }
        else {
            cell.textLabel?.text = chain.key.publicKey.base58
        }
        cell.detailTextLabel?.text = "\(chain.height) bks"

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Removing", message: "Remove this chain and its all blocks from local?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                self.manager.remove(chain: self.manager.allChains[indexPath.row])
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: .left)
                self.tableView.endUpdates()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }
}
