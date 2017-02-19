//
//  EditableFUITableViewDataSource.swift
//  
//
//  Created by Thomas Hocking on 1/29/17.
//
//

import UIKit
import FirebaseDatabaseUI

class EditableFUITableViewDataSource: FUITableViewDataSource {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
