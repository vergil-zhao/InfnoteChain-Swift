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
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "InfnoteChain.Peer.Connected"), object: nil, queue: OperationQueue.main) { _ in
            self.tableView.reloadData()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "InfnoteChain.Peer.Disconnected"), object: nil, queue: OperationQueue.main) { _ in
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        peers = Array<Peer>(PeerManager.shared.allPeers)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peer = peers[indexPath.row]
        if ShareManager.shared.isConnected(with: peer) {
            ShareManager.shared.disconnect(to: peer)
        }
        else {
            ShareManager.shared.connect(to: peer)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let peer = peers[indexPath.row]
        cell.textLabel?.text = "\(peer.address):\(peer.port)"
        cell.detailTextLabel?.text = "\(peer.rank)"
        if ShareManager.shared.isConnected(with: peer) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            PeerManager.shared.remove(peers[indexPath.row])
            peers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }

}
