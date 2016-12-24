//
//  ParticipantsViewController.swift
//  FoodTrain
//
//  Created by Dmytro Zozulia on 11/10/16.
//  Copyright © 2016 FoodTrain. All rights reserved.
//

import Cocoa

class ParticipantsViewController: NSViewController {

  var participants: [String]?
  @IBOutlet weak var tableView: NSTableView!

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.dataSource = self
    self.tableView.delegate = self
    let count = participants?.count ?? 0
    self.view.setFrameSize(NSSize(width: 150.0, height: 20.0 * CGFloat(count)))
  }
}

extension ParticipantsViewController: NSTableViewDataSource {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return participants?.count ?? 0
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.make(withIdentifier: "ParticipantsCell", owner: self) as! ParticipantsCell
    cell.textField?.stringValue = participants?[row] ?? ""
    return cell
  }
}

extension ParticipantsViewController: NSTableViewDelegate {

}
