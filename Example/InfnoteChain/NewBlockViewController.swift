//
//  NewBlockViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/9/30.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit
import InfnoteChain

class NewBlockViewController: UITableViewController, UITextViewDelegate {
    
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var createButton: UIButton!
    
    var chain: Blockchain!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !chain.isOwner {
            navigationItem.title = "Add Signed Block"
            createButton.setTitle("ADD", for: .normal)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textViewHeightConstraint.constant = textView.sizeThatFits(textView.frame.size).height
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    @IBAction func createButtonTouched(_ sender: Any) {
        if !textView.text.isEmpty{
            var block: Block? = nil
            
            if chain.isOwner {
                block = chain.createBlock(withPayload: textView.text.data(using: .utf8)!)
            }
            else {
                block = Block(jsonData: textView.text.data(using: .utf8)!)
            }
            
            let controller = storyboard?.instantiateViewController(withIdentifier: "BlockDetail") as! BlockDetailViewController
            controller.block = block
            controller.isConfirmable = true
            
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        navigationController?.dismiss(animated: true)
    }
}
