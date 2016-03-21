//
//  FolioReaderMyNote.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 01/09/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

class FolioReaderMyNote: UIViewController, UITableViewDelegate, UITableViewDataSource, FolioReaderMemoDelegate {  //UITableViewController

    var highlights: [Highlight]!
    var editingHighlight: Highlight?
    var tableView: UITableView = UITableView()
    let folioReaderMemo = FolioReaderMemo()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.folioReaderMemo.delegate = self  //デリゲートパターン
        
        let barHeight: CGFloat = UIApplication.sharedApplication().statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        // TableViewの生成( status barの高さ分ずらして表示 ).
        tableView.frame = CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight)
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.backgroundColor = isNight(readerConfig.nightModeBackground, UIColor.whiteColor())
        tableView.separatorColor = isNight(readerConfig.nightModeSeparatorColor, readerConfig.menuSeparatorColor)
    
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
        
        highlights = Highlight.allByBookId((kBookId as NSString).stringByDeletingPathExtension)
        print("highlightsは \(highlights)")
        title = readerConfig.localizedHighlightsTitle
        
        setCloseButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        //Memo.swiftから戻ってくるたびに (メモ含む)テーブルの内容を更新
        self.tableView.reloadData()
        
        super.viewWillAppear(animated)
        configureNavBar()
    }
    
    func configureNavBar() {
        let navBackground = isNight(readerConfig.nightModeMenuBackground, UIColor.whiteColor())
        let tintColor = readerConfig.tintColor
        let navText = isNight(UIColor.whiteColor(), UIColor.blackColor())
        let font = UIFont(name: "Avenir-Light", size: 17)!
        setTranslucentNavigation(color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return highlights.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) 
        cell.backgroundColor = UIColor.clearColor()

        let highlight = highlights[indexPath.row]
        
        // Format date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = readerConfig.localizedHighlightsDateFormat
        let dateString = dateFormatter.stringFromDate(highlight.date)
        
        // Add Date
        var dateLabel: UILabel!
        if cell.contentView.viewWithTag(456) == nil {
            dateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 16))
            dateLabel.tag = 456
            dateLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth
            dateLabel.font = UIFont(name: "Avenir-Medium", size: 12)
            cell.contentView.addSubview(dateLabel)
        } else {
            dateLabel = cell.contentView.viewWithTag(456) as! UILabel
        }
        
        dateLabel.text = dateString.uppercaseString
        dateLabel.textColor = isNight(UIColor(white: 5, alpha: 0.3), UIColor.lightGrayColor())
        dateLabel.frame = CGRect(x: 20, y: 20, width: view.frame.width-40, height: dateLabel.frame.height)
        
        // Make Highlight Text
        let cleanHighlightString = highlight.content.stripHtml().truncate(250, trailing: "...").stripLineBreaks()  //最大で250文字まで表示
        let text = NSMutableAttributedString(string: cleanHighlightString)
        let range = NSRange(location: 0, length: text.length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        let textColor = isNight(readerConfig.menuTextColor, UIColor.blackColor())
        
        text.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
        text.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Light", size: 16)!, range: range)
        text.addAttribute(NSForegroundColorAttributeName, value: textColor, range: range)
        
        if highlight.type.integerValue == HighlightStyle.Underline.rawValue {
            text.addAttribute(NSBackgroundColorAttributeName, value: UIColor.clearColor(), range: range)
            text.addAttribute(NSUnderlineColorAttributeName, value: HighlightStyle.colorForStyle(highlight.type.integerValue, nightMode: FolioReader.sharedInstance.nightMode), range: range)
            text.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue), range: range)
        } else {
            text.addAttribute(NSBackgroundColorAttributeName, value: HighlightStyle.colorForStyle(highlight.type.integerValue, nightMode: FolioReader.sharedInstance.nightMode), range: range)
        }
        
        // Add Highlight Text
        var highlightLabel: UILabel!
        if cell.contentView.viewWithTag(123) == nil {
            highlightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 0))
            highlightLabel.tag = 123
            highlightLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth
            highlightLabel.numberOfLines = 0
            highlightLabel.textColor = UIColor.blackColor()
            cell.contentView.addSubview(highlightLabel)
        } else {
            highlightLabel = cell.contentView.viewWithTag(123) as! UILabel
        }
 
        highlightLabel.attributedText = text
        highlightLabel.sizeToFit()
        highlightLabel.frame = CGRect(x: 20, y: 46, width: view.frame.width-40, height: highlightLabel.frame.height)

        // Make Memo Text
        if(highlight.memo != nil){
            let cleanMemoString = highlight.memo!.truncate(150, trailing: "...").stripLineBreaks()  //最大で150文字まで表示
            let memoText = NSMutableAttributedString(string: cleanMemoString)
            let memoTextRange = NSRange(location: 0, length: memoText.length)
            let memoTextParagraph = NSMutableParagraphStyle()
            memoTextParagraph.lineSpacing = 3
        
            memoText.addAttribute(NSParagraphStyleAttributeName, value: memoTextParagraph, range: memoTextRange)
            memoText.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Light", size: 14)!, range: memoTextRange)
            memoText.addAttribute(NSForegroundColorAttributeName, value: textColor, range: memoTextRange)
            
            //Add Memo Text
            var memoLabel: UILabel!
            if cell.contentView.viewWithTag(789) == nil {
                memoLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-40, height: 0))
                memoLabel.tag = 789
                memoLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth
                memoLabel.numberOfLines = 0
                memoLabel.textColor = UIColor.blackColor()
                cell.contentView.addSubview(memoLabel)
            } else {
                memoLabel = cell.contentView.viewWithTag(789) as! UILabel
            }
            
            memoLabel.attributedText = memoText
            memoLabel.sizeToFit()
            memoLabel.frame = CGRect(x: 20, y: 46+highlightLabel.frame.height+10, width: view.frame.width-40, height: memoLabel.frame.height)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let highlight = highlights[indexPath.row]
        
        let cleanString = highlight.content.stripHtml().truncate(250, trailing: "...").stripLineBreaks()
        let text = NSMutableAttributedString(string: cleanString)
        let range = NSRange(location: 0, length: text.length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        text.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
        text.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Light", size: 16)!, range: range)
        
        let highlightTextBoundingRect = text.boundingRectWithSize(CGSize(width: view.frame.width-40, height: CGFloat.max),
            options: [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading],
            context: nil)
        
        
        let memoText:NSMutableAttributedString?
        var memoTextBoundingRectHeight:CGFloat = 0
        
        //メモがあれば その分の高さを追加
        if(highlight.memo != nil){
            let cleanMemoString = highlight.memo!.truncate(150, trailing: "...").stripLineBreaks()  //最大で150文字まで表示
            memoText = NSMutableAttributedString(string: cleanMemoString)
            let memoTextRange = NSRange(location: 0, length: memoText!.length)
            let memoTextParagraph = NSMutableParagraphStyle()
            memoTextParagraph.lineSpacing = 3
            
            memoText!.addAttribute(NSParagraphStyleAttributeName, value: memoTextParagraph, range: memoTextRange)
            memoText!.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Light", size: 14)!, range: memoTextRange)
            
            let memoTextBoundingRect = memoText!.boundingRectWithSize(CGSize(width: view.frame.width-40, height: CGFloat.max),
                options: [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading],
                context: nil)
            memoTextBoundingRectHeight = memoTextBoundingRect.size.height
        }
        
        return highlightTextBoundingRect.size.height + memoTextBoundingRectHeight + 66  //66はDateの部分
    }
    
    // MARK: - Table view delegate  //tap gesture
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let highlight = highlights[indexPath.row]

        FolioReader.sharedInstance.readerCenter.changePageWith(page: highlight.page.integerValue, andFragment: highlight.highlightId)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        // メモをタップ
        let edit = UITableViewRowAction(style: .Normal, title: "Memo") {
            (action, indexPath) in
            
            //webview内でのロングタップによるメモの表示および更新 はどうする?
            //→とりあえずMyNoteからのメモの更新だけにする
            
            self.editingHighlight = self.highlights[indexPath.row]
         
            self.presentViewController(self.folioReaderMemo, animated: true, completion: nil)
        }
        
        edit.backgroundColor = UIColor.greenColor()
        
        // 削除をタップ
        let del = UITableViewRowAction(style: .Default, title: "Delete") {
            (action, indexPath) in
            
            let highlight = self.highlights[indexPath.row]
            if highlight.page == currentPageNumber {
                FRHighlight.removeById(highlight.highlightId) // Remove from HTML
            }
            
            Highlight.removeById(highlight.highlightId) // Remove from Core data
            self.highlights.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        
        del.backgroundColor = UIColor.redColor()
        
        return [edit, del]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {

        //let tmp = itemArray[sourceIndexPath.row]
        //itemArray.removeAtIndex(sourceIndexPath.row)
        //itemArray.insert(tmp, atIndex: destinationIndexPath.row)
    }
    
    // スワイプで処理する場合 ここでは何もしないが関数は必要?
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    //　MARK: protocol implementation
    func modalDidFinished(modalText: String) {
        //Core dataを更新
        Highlight.updateMemoById(editingHighlight!.highlightId, newMemo: modalText)
    }
    
    // MARK: - Handle rotation transition
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
}
