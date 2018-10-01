//
//  NewChainViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/9/29.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit
import InfnoteChain

class NewChainViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var fields: [UITextField]!
    @IBOutlet weak var descField: UITextView!
    
    let keyNames = ["name", "version", "author", "website", "email"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    @IBAction func createButtonTouched(_ sender: Any) {
        
        var info: [String: Any] = [:]
        for i in 0...4 {
            if let content = fields[i].text, !content.isEmpty {
                info[keyNames[i]] = content
            }
            else if let placeholder = fields[i].placeholder, !placeholder.isEmpty {
                info[keyNames[i]] = placeholder
            }
        }
        if !descField.text.isEmpty {
            info["desc"] = descField.text
        }
        _ = ChainManager.shared.create(chain: info)
        
        navigationController?.popViewController(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let index = fields.firstIndex(of: textField) {
            if index < 4 {
                fields[index + 1].becomeFirstResponder()
            }
            else {
                descField.becomeFirstResponder()
            }
        }
        
        return true
    }
}
