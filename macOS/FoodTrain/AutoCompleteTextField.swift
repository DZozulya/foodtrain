//
//  AutoCompleteTextField.swift
//  FoodTrain
//
//  Created by Leon Stellbrink on 11/10/16.
//  Copyright © 2016 Yelp Inc. All rights reserved.
//

import Cocoa

@objc protocol AutoCompleteTableViewDelegate:NSObjectProtocol{
    func textField(textField:NSTextField,completions words:[String],forPartialWordRange charRange:NSRange,indexOfSelectedItem index:Int) ->[String]?
    @objc optional func didSelectItem(selectedItem: String)
}

class AutoCompleteTableRowView:NSTableRowView{
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none{
            let selectionRect = NSInsetRect(self.bounds, 0.5, 0.5)
            NSColor.selectedMenuItemColor.setStroke()
            NSColor.selectedMenuItemColor.setFill()
            let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: 0.0, yRadius: 0.0)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }
    
    override var interiorBackgroundStyle:NSBackgroundStyle{
        get{
            if self.isSelected {
                return NSBackgroundStyle.dark
            }
            else{
                return NSBackgroundStyle.light
            }
        }
    }
}

class AutoCompleteTextField:NSTextField{
    weak var tableViewDelegate:AutoCompleteTableViewDelegate?
    var popOverWidth:NSNumber = 110
    let popOverPadding:CGFloat = 0.0
    let maxResults = 10
    
    var autoCompletePopover:NSPopover?
    weak var autoCompleteTableView:NSTableView?
    var matches:[String]?
  
  func setMatchesManually(matches: [String]) {
    self.matches = matches;
    if self.matches!.count > 0 {
      showMatches(selectedIndex: 0)
    }
  }
  
    override func awakeFromNib() {
        let column1 = NSTableColumn(identifier: "text")
        column1.isEditable = false
        column1.width = CGFloat(popOverWidth.floatValue) - 2 * popOverPadding
        
        let tableView = NSTableView(frame: NSZeroRect)
        tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyle.regular
        tableView.backgroundColor = NSColor.clear
        tableView.rowSizeStyle = NSTableViewRowSizeStyle.small
        tableView.intercellSpacing = NSMakeSize(10.0, 0.0)
        tableView.headerView = nil
        tableView.refusesFirstResponder = true
        tableView.target = self
        tableView.doubleAction = #selector(AutoCompleteTextField.insert(sender:))
        tableView.addTableColumn(column1)
        tableView.delegate = self//  setDelegate(self)
        tableView.dataSource = self // setDataSource(self)
        self.autoCompleteTableView = tableView
        
        let tableSrollView = NSScrollView(frame: NSZeroRect)
        tableSrollView.drawsBackground = false
        tableSrollView.documentView = tableView
        tableSrollView.hasVerticalScroller = true
        
        let contentView:NSView = NSView(frame: NSZeroRect)
        contentView.addSubview(tableSrollView)
        
        let contentViewController = NSViewController()
        contentViewController.view = contentView
        
        self.autoCompletePopover = NSPopover()
        self.autoCompletePopover?.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
        self.autoCompletePopover?.animates = false
        self.autoCompletePopover?.contentViewController = contentViewController
        
        self.matches = [String]()
    }
    
    override func keyUp(with: NSEvent) {
        let row:Int = self.autoCompleteTableView!.selectedRow
        let isShow = self.autoCompletePopover!.isShown
        switch(with.keyCode){
            
        case 125: //Down
            if isShow{
                self.autoCompleteTableView?.selectRowIndexes(NSIndexSet(index: row + 1) as IndexSet, byExtendingSelection: false)
                self.autoCompleteTableView?.scrollRowToVisible((self.autoCompleteTableView?.selectedRow)!)
                return //skip default behavior
            }
            
        case 126: //Up
            if isShow{
                self.autoCompleteTableView?.selectRowIndexes(NSIndexSet(index: row - 1) as IndexSet, byExtendingSelection: false)
                self.autoCompleteTableView?.scrollRowToVisible((self.autoCompleteTableView?.selectedRow)!)
                return //skip default behavior
            }
        
        case 36: // Return
            if isShow{
                self.insert(sender: self)
                return //skip default behavior
            }
            
        case 48: //Tab
            if isShow{
                self.insert(sender: self)
            }
            return
        
        case 49: //Space
            if isShow {
                self.insert(sender: self)
            }
            return
            
        default:
            break
        }
        
        super.keyUp(with: with)
        self.complete(self)
    }

    func insert(sender:AnyObject){
        let selectedRow = self.autoCompleteTableView!.selectedRow
        let matchCount = self.matches!.count
        if selectedRow >= 0 && selectedRow < matchCount{
            self.stringValue = self.matches![selectedRow]
            if self.tableViewDelegate!.responds(to: #selector(AutoCompleteTableViewDelegate.didSelectItem(selectedItem:))){
              self.tableViewDelegate!.didSelectItem!(selectedItem:self.stringValue)
            }
        }
        self.autoCompletePopover?.close()
    }
    
    @objc override func complete(_ sender: Any?) {
        let lengthOfWord = self.stringValue.characters.count
        let subStringRange = NSMakeRange(0, lengthOfWord)
        
        //This happens when we just started a new word or if we have already typed the entire word
        if subStringRange.length == 0 || lengthOfWord == 0 {
            Swift.print("complete lengthOfWord = \(lengthOfWord) identier = \((sender as! NSTextField).identifier)")
            self.autoCompletePopover?.close()
            return
        }
        
        let index = 0
      if (self.completionsForPartialWordRange(charRange: subStringRange, indexOfSelectedItem: index) != nil) {
        self.matches = self.completionsForPartialWordRange(charRange: subStringRange, indexOfSelectedItem: index)!
        
        if self.matches!.count > 0 {
          showMatches(selectedIndex: index)
        }
        else{
            self.autoCompletePopover?.close()
        }
      }
    }
  
  func showMatches(selectedIndex: Int) {
    self.autoCompleteTableView?.reloadData()
    self.autoCompleteTableView?.selectRowIndexes(NSIndexSet(index: selectedIndex) as IndexSet, byExtendingSelection: false)
    self.autoCompleteTableView?.scrollRowToVisible(selectedIndex)
    
    let numberOfRows = min(self.autoCompleteTableView!.numberOfRows, maxResults)
    let height = (self.autoCompleteTableView!.rowHeight + self.autoCompleteTableView!.intercellSpacing.height) * CGFloat(numberOfRows) + 2 * 0.0
    let frame = NSMakeRect(0, 0, CGFloat(popOverWidth.floatValue), height)
    self.autoCompleteTableView?.enclosingScrollView?.frame = NSInsetRect(frame, popOverPadding, popOverPadding)
    self.autoCompletePopover?.contentSize = NSMakeSize(NSWidth(frame), NSHeight(frame))
    
    let rect = self.visibleRect
    self.autoCompletePopover?.show(relativeTo: rect, of: self, preferredEdge: NSRectEdge.maxY)
  }
  
    func completionsForPartialWordRange(charRange: NSRange, indexOfSelectedItem index: Int) ->[String]?{
        if self.tableViewDelegate!.responds(to: #selector(AutoCompleteTableViewDelegate.textField(textField:completions:forPartialWordRange:indexOfSelectedItem:))){
            return self.tableViewDelegate!.textField(textField: self, completions: [], forPartialWordRange: charRange, indexOfSelectedItem: index)
        }
        return []
    }
}

// MARK: - NSTableViewDelegate
extension AutoCompleteTextField:NSTableViewDelegate{
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return AutoCompleteTableRowView()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellView = tableView.make(withIdentifier: "MyView", owner: self) as? NSTableCellView
        if cellView == nil{
            cellView = NSTableCellView(frame: NSZeroRect)
            let textField = NSTextField(frame: NSZeroRect)
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.isEditable = false
            textField.isSelectable = false
            cellView!.addSubview(textField)
            cellView!.textField = textField
            cellView!.identifier = "MyView"
        }
        let attrs = [NSForegroundColorAttributeName:NSColor.black,NSFontAttributeName:NSFont.systemFont(ofSize: 13)]
      if self.matches!.count > row {
        let mutableAttriStr = NSMutableAttributedString(string: self.matches![row], attributes: attrs)
        cellView!.textField!.attributedStringValue = mutableAttriStr
      }
        
        return cellView
    }
}

// MARK: - NSTableViewDataSource
extension AutoCompleteTextField:NSTableViewDataSource{
    func numberOfRows(in _: NSTableView) -> Int {
        if self.matches == nil{
            return 0
        }
        return self.matches!.count
    }
}
