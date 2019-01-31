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

    var chains: [Chain] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(forName: .init(rawValue: "com.infnote.block.saved"), object: nil, queue: OperationQueue.main) { _ in
            self.tableView.reloadData()
        }
        
        chains = Storage.shared.getAllChains()
    }
    
    @IBAction func debugButtonTouched(_ sender: Any) {
        print(Storage.shared.fileURL)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chains.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChainCell

        cell.nameLabel.text = chains[indexPath.row].id
        cell.heightLabel.text = "\(chains[indexPath.row].count)"
        
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
            Storage.shared.clean(chain: chains[indexPath.row])
            chains.remove(at: indexPath.row)
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .left)
            self.tableView.endUpdates()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chain_detail" {
            let vc = segue.destination as! BlocksViewController
            vc.chain = chains[self.tableView.indexPathForSelectedRow!.row]
        } else if segue.identifier == "add_chain" {
            let vc = segue.destination as! AddChainViewController
            vc.onSave = {
                self.chains = Storage.shared.getAllChains()
                self.tableView.reloadData()
            }
        }
    }
}


class ChainCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    
}
