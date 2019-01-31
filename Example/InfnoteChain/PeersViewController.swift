//
//  PeersViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/10/22.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import InfnoteChain

class PeersViewController: UITableViewController {
    
    var peers: [Peer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "com.infnote.peer.connected"), object: nil, queue: OperationQueue.main) { _ in
            self.tableView.reloadData()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "com.infnote.peer.disconnected"), object: nil, queue: OperationQueue.main) { _ in
            self.tableView.reloadData()
        }
        
        peers = Array<Peer>(PeerManager.shared.allPeers)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peer = peers[indexPath.row]
        if peer.isConnected {
            peer.disconnect()
        } else {
            peer.connect()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let peer = peers[indexPath.row]
        cell.textLabel?.text = "\(peer.address)"
        cell.detailTextLabel?.text = "\(peer.rank)"
        if peer.isConnected {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let peer = peers[indexPath.row]
            peer.disconnect()
            PeerManager.shared.remove(peer)
            peers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }

}
