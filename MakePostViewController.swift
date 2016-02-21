//
//  MakePostViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/21/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

class MakePostViewController: UIViewController {

    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Make a Post"
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
        navigationItem.leftBarButtonItem = cancelButton
    }
}
