//
//  PostTableViewCell.swift
//  On the Map
//
//  Created by Michael Miller on 2/19/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

//this custom UITableView subclass was created so that the table view cells could be customized with several labels, as laid out in the interface builder; there is a label for the user's name, the URL, as well as labels for the date of the post and the location ("mapstring"), as posted by another udacity user
class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
}
