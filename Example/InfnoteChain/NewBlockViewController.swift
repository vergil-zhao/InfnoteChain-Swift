//
//  NewBlockViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/9/30.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import InfnoteChain

class NewBlockViewController: UITableViewController, UITextViewDelegate {
    
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    
    var chain: Blockchain?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func textViewDidChange(_ textView: UITextView) {
        textViewHeightConstraint.constant = textView.sizeThatFits(textView.frame.size).height
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    @IBAction func createButtonTouched(_ sender: Any) {
        if !textView.text.isEmpty {
            let block = chain?.createBlock(withPayload: textView.text.data(using: .utf8)!)
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
