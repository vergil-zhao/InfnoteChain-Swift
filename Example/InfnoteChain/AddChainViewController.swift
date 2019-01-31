//
//  AddChainViewController.swift
//  InfnoteChain_Example
//
//  Created by Vergil Choi on 2018/9/30.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit
import InfnoteChain

class AddChainViewController: UITableViewController {
    
    var onSave: (() -> Void)?

    @IBOutlet weak var textField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func addButtonTouched(_ sender: Any) {
        if let content = textField.text, content.count > 0 {
            let chain = Chain()
            chain.id = content
            chain.save()
            navigationController?.popViewController(animated: true)
            onSave?()
            onSave = nil
        }
    }
}
