//
//  BlocksViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/9/30.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit
import InfnoteChain

class BlocksViewController: UITableViewController {
    
    var chain: Blockchain!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "InfnoteChain.Block.Saved"), object: nil, queue: OperationQueue.main) { _ in
            self.tableView.reloadData()
        }
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
        return chain.height
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = "\(indexPath.row)"
        if let block = chain[indexPath.row] {
            cell.detailTextLabel?.text = block.payload.humanReadableSize
        }
        else {
            cell.detailTextLabel?.text = "Error!"
        }

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail" {
            let controller = segue.destination as! BlockDetailViewController
            controller.block = chain[tableView.indexPathForSelectedRow!.row]
        }
        else if segue.identifier == "add" {
            let controller = (segue.destination as! UINavigationController).viewControllers.first as! NewBlockViewController
            controller.chain = chain
        }
    }

}
