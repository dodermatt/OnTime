//
//  AutocompleteTextfield.swift
//  AutocompleteTextfieldSwift
//
//  Created by Mylene Bayan on 2/21/15.
//  Copyright (c) 2015 MaiLin. All rights reserved.
//

import Foundation
import UIKit


@objc protocol AutocompleteTextFieldDelegate{
  /**
  Sends the selected string to the conforming class
  
  :param: text      the selected string from the list of suggestions
  :param: indexPath the position of the selected string on the tableview
  */
  func didSelectAutocompleteText(text:String, indexPath:NSIndexPath)
  
  /**
  Observes text changes on the textfield and send it to the conforming class, in here you may want to process the user-typed text to provide your suggestions
  
  :param: text the current text content of the textfield
  */
  optional func autoCompleteTextFieldDidChange(text:String)
  optional func autoCompleteTextStartEditing()
}

@objc class AutocompleteTextfield:UITextField, UITableViewDataSource, UITableViewDelegate{

  var autoCompleteDelegate:AutocompleteTextFieldDelegate?
  
  /// The strings to be shown on as suggestions, setting the value of this automatically reload the tableview
  var autoCompleteStrings:[String]?{
    didSet{
      reloadAutoCompleteData()
    }
  }
  
  /// Font for the text suggestions
  var autoCompleteTextFont = UIFont(name: "HelveticaNeue-Light", size: 12)
  
  /// Color of the text suggestions
  var autoCompleteTextColor = UIColor.whiteColor()
  
  /// Used to set the height of cell for each suggestions
  var autoCompleteCellHeight:CGFloat = 44.0
  
  /// The maximum visible suggestion
  var maximumAutoCompleteCount = 3
  
  /// Used to set your own preferred separator inset
  var autoCompleteSeparatorInset = UIEdgeInsetsZero
  
  /// Hides autocomplete tableview when the textfield is empty
  var hideWhenEmpty:Bool?{
    didSet{
      tableViewSetHidden(hideWhenEmpty!)
    }
  }
  
  /// Hides autocomplete tableview after selecting a suggestion
  var hideWhenSelected = true
  
  /// Shows autocomplete text with formatting
  var enableAttributedText = false
  
  /// User Defined Attributes
  var autoCompleteAttributes:Dictionary<String,AnyObject>?
  
  /// The table view height
  var autoCompleteTableHeight:CGFloat = 100.0
  
  /// Manages the instance of tableview
  private var autoCompleteTableView:UITableView?
  
  private var attributedAutocompleteStrings:[NSAttributedString]?
  

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    initialize()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    initialize()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    initialize()
  }
  
  
  //MARK: Initialization
  func initialize(){
    
    autoCompleteAttributes = [NSForegroundColorAttributeName:UIColor.darkGrayColor()]
    autoCompleteAttributes![NSFontAttributeName] = UIFont(name: "HelveticaNeue-Bold", size: 12)
  }
  
  func setupTextField(){
    self.clearButtonMode = .WhileEditing
    self.addTarget(self, action: "textFieldDidChange", forControlEvents: .EditingChanged)
    self.addTarget(self, action: "textFieldDidBegin", forControlEvents: .EditingDidBegin)
  }
  
  func setupTableView(){
    let screenSize = UIScreen.mainScreen().bounds.size
    let tableView = UITableView(frame: CGRectMake(self.frame.origin.x, self.frame.origin.y + CGRectGetHeight(self.frame), screenSize.width - (self.frame.origin.x * 2), autoCompleteTableHeight))
    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = UIColor.clearColor()
    tableView.tableFooterView = UIView()
    self.superview?.addSubview(tableView)
    
    autoCompleteTableView = tableView
    tableViewSetHidden(true)
  }

  private func tableViewSetHidden(hidden:Bool){
    autoCompleteTableView?.hidden = hidden
  }
  
  private func reloadAutoCompleteData(){
    if enableAttributedText{
      let attrs = [NSForegroundColorAttributeName:autoCompleteTextColor, NSFontAttributeName:UIFont.systemFontOfSize(12)]
      if attributedAutocompleteStrings == nil{
          attributedAutocompleteStrings = [NSAttributedString]()
      }
      else{
        if attributedAutocompleteStrings?.count > 0 {
          attributedAutocompleteStrings?.removeAll(keepCapacity: false)
        }
      }
      
      if autoCompleteStrings != nil{
        for i in 0..<autoCompleteStrings!.count{
          let str = autoCompleteStrings![i] as NSString
          let range = str.rangeOfString(text, options: .CaseInsensitiveSearch)
          var attString = NSMutableAttributedString(string: str as String!, attributes: attrs)
          attString.addAttributes(autoCompleteAttributes!, range: range)
          attributedAutocompleteStrings?.append(attString)
        }
      }
    }
    autoCompleteTableView?.reloadData()
  }
  
  func textFieldDidChange(){
    autoCompleteDelegate?.autoCompleteTextFieldDidChange?(text)
    
    if text.isEmpty{
      autoCompleteStrings = nil
    }
    
    hideWhenEmpty = hideWhenEmpty != nil ? hideWhenEmpty! : true
    
    if hideWhenEmpty! {
      tableViewSetHidden(text.isEmpty)
    }
    else{
      tableViewSetHidden(false)
    }
  }
    
  func textFieldDidBegin(){
    if text.isEmpty{
        autoCompleteStrings = nil
    }
    
    hideWhenEmpty = hideWhenEmpty != nil ? hideWhenEmpty! : true
    if hideWhenEmpty! {
        tableViewSetHidden(text.isEmpty)
    }
    else{
        tableViewSetHidden(false)
    }
    autoCompleteDelegate?.autoCompleteTextStartEditing!()
  }
  
  //MARK: UITableViewDataSource
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return autoCompleteStrings != nil ? (autoCompleteStrings!.count > maximumAutoCompleteCount ? maximumAutoCompleteCount : autoCompleteStrings!.count) : 0
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return autoCompleteCellHeight
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cellIdentifier = "autocompleteCellIdentifier"
    var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
    if cell == nil{
      cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
    }
    
    if enableAttributedText{
      cell?.textLabel?.attributedText = attributedAutocompleteStrings![indexPath.row]
    }
    else{
      cell?.textLabel?.font = autoCompleteTextFont
      cell?.textLabel?.textColor = autoCompleteTextColor
      cell?.textLabel?.text = autoCompleteStrings![indexPath.row]
    }
    cell?.backgroundColor = UIColor.clearColor()
    var bgColorView = UIView()
    bgColorView.backgroundColor = UIColor(red:1.0, green:1.0,blue:1.0,alpha:0.2)
    bgColorView.layer.cornerRadius = 6
    cell?.selectedBackgroundView = bgColorView
    
    return cell!
  }
  
  
  //MARK: UITableViewDelegate
  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if cell.respondsToSelector("setSeparatorInset:"){
      //cell.separatorInset = autoCompleteSeparatorInset
    }
    
    if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:"){
      cell.preservesSuperviewLayoutMargins = false
    }
    
    if cell.respondsToSelector("setLayoutMargins:"){
      cell.layoutMargins = autoCompleteSeparatorInset
    }
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    let cell = tableView.cellForRowAtIndexPath(indexPath)
    let text = cell?.textLabel?.text
    self.text = text
    
    autoCompleteDelegate?.didSelectAutocompleteText(text!, indexPath: indexPath)
    tableViewSetHidden(hideWhenSelected)
    self.autoCompleteStrings = nil
  }
  
}
