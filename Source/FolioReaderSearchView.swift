//
//  FolioReaderSearchView.swift
//  Pods
//
//  Created by taku on 2016/03/08.
//
//

import UIKit

class FolioReaderSearchView: UIViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate {
  
    private var search: UISearchBar?
    private var table: UITableView?
    private var barHeight: CGFloat?
    private var displayWidth: CGFloat?
    private var displayHeight: CGFloat?
    private let SEARCHBAR_HEIGHT: CGFloat = 44
    private var matches:[NSTextCheckingResult]?
    private var matchesStrArray:[String] = []
    private var html:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        //とりあえず本全体(全文検索?)ではなく章単位での検索にする
        self.html = FolioReader.sharedInstance.readerCenter.currentPage.getHTML()
        print("htmlは. \(self.html)")
        
        barHeight = UIApplication.sharedApplication().statusBarFrame.size.height  //0
        displayWidth = self.view.frame.width
        displayHeight = self.view.frame.height
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.search = UISearchBar();   //self.search? =  とするとエラー　　Optional Chainingになるため
        self.search!.delegate = self
        self.search!.frame = CGRectMake(0, 0, displayWidth!, SEARCHBAR_HEIGHT)  //サイズ
        self.search!.layer.position = CGPoint(x: self.view.bounds.width/2, y: 80)  //配置場所
        self.search!.showsCancelButton = false
        self.search!.placeholder = "検索する"
        self.view.addSubview(search!)
        
        setCloseButton()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar){   //protocolの実装
        print("searchtextは \(search!.text!)")
        
        //機能追加: 何度も検索を可能にする、下の方の検索結果も見えるように
        
        let pattern = "([a-zA-Z0-9]|.){0,10}\(search!.text!)([a-zA-Z0-9]|.){0,10}"  //それぞれの前後の文字列も確保?
        //"\(search!.text!)"  //バグ修正: 一致する文字列があると個別に移動できない..
        
        print("patternは \(pattern)")
      
        self.matches =  RegExp(pattern).matches(self.html!)
        print("matchesは\(self.matches)")
        
        if(self.matches != nil){
            
            for i in 0 ..< self.matches!.count {
                self.matchesStrArray.append( (self.html! as NSString).substringWithRange(self.matches![i].range) )
            }
           
            if(self.table == nil){
                
                self.addTable()
            }
            
            //下にリロードしたら動的に列を追加したい(最初は10件まで表示?)
            /*self.table!.beginUpdates()
            self.matches = searchResult
            var indexPathArray:[NSIndexPath]=[]
            for row in 0..<self.matches!.count {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                indexPathArray.append(indexPath)
            }
            self.table!.insertRowsAtIndexPaths(indexPathArray, withRowAnimation: .Top)
            self.table!.endUpdates()
            self.table!.reloadData()*/
            
        }else{
            //self.showAlert("検索結果がありません",title: "",buttonTitle: "了解")
        }
    }
    //バグ修正: タグ抜き検索したい?
    /*let href = splitedPath[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "/"))
    let hrefPage = FolioReader.sharedInstance.readerCenter.findPageByHref(href)+1
    
    if hrefPage == pageNumber {
    // Handle internal #anchor
    if anchorFromURL != nil {
    handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animating: true)
    return false
    }
    } else {
    FolioReader.sharedInstance.readerCenter.changePageWith(href: href, animated: true)
    }*/
  
    func addTable(){

        print("self.tableは\(self.table)") //この時の中身はnil
        self.table = UITableView();  //インスタンスを代入　これにより中身がnilでなくなる
        self.table!.frame = CGRectMake(0, barHeight! + SEARCHBAR_HEIGHT + 60, displayWidth!, displayHeight! - barHeight! - SEARCHBAR_HEIGHT - 60);
        self.table!.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.table!.delegate = self
        self.table!.dataSource = self;
        self.view.addSubview(table!)
    }
    
    
//以下、検索して確保したそれぞれの結果をテーブルビューに列挙(スクロール?)
//#pragma mark - UITableView DataSource
    
    //Table Viewのセルの数を指定
    func tableView(table: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        print("カウントは\(self.matches!.count)")
        return self.matches!.count
    }
    
    //各セルの要素を設定する
    func tableView(table: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       
        print("indexPath == \(indexPath)")
        
        // tableCell の ID で UITableViewCell のインスタンスを生成
        let cell = table.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = "\(matchesStrArray[indexPath.row])"
        
        return cell
    }
    
    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        print("tappした \(indexPath)")
        
        let item = self.matches![indexPath.row]
        let content = (self.html! as NSString).substringWithRange(item.range)
        let searchTagId = "search"
        
    //正規表現検索+searchタグの挿入操作 をネイティブ側ではなく、JS側でやることでうまくいきそう
    //もしくは以下のやり方
        self.dismissViewControllerAnimated(true, completion: nil)
        
        var htmls = (self.html! as NSString)
        let style = HighlightStyle.classForStyle(2)  //青色
        let tag = "<search id=\"\(searchTagId)\" class=\"\(style)\">\(content)</search>"
        let range: NSRange = htmls.rangeOfString(content, options: .LiteralSearch)
        if range.location != NSNotFound {
            let newRange = NSRange(location: range.location, length: content.characters.count)
            htmls = htmls.stringByReplacingCharactersInRange(newRange, withString: tag)
            
            let currentPageNum = FolioReader.sharedInstance.readerCenter.currentPage.pageNumber
            let resource = book.spine.spineReferences[currentPageNum-1].resource
            FolioReader.sharedInstance.readerCenter.currentPage.webView.tag = 1  //didfinishLoad時に行移動させるため
            FolioReader.sharedInstance.readerCenter.currentPage.webView.alpha = 0
            FolioReader.sharedInstance.readerCenter.currentPage.webView.loadHTMLString(htmls as String, baseURL: NSURL(fileURLWithPath: (resource.fullHref as NSString).stringByDeletingLastPathComponent))
            
            print("htmls is \(htmls)")
        }
        else {
            print("item range not found")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}















/*
var highlights: [Highlight]!

override func viewDidLoad() {
super.viewDidLoad()

tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
tableView.backgroundColor = isNight(readerConfig.nightModeBackground, UIColor.whiteColor())
tableView.separatorColor = isNight(readerConfig.nightModeSeparatorColor, readerConfig.menuSeparatorColor)

highlights = Highlight.allByBookId((kBookId as NSString).stringByDeletingPathExtension)
title = readerConfig.localizedHighlightsTitle

setCloseButton()
}

override func viewWillAppear(animated: Bool) {
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



// MARK: - Table view data source

override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
return 1
}

override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
return highlights.count
}

override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
cell.backgroundColor = UIColor.clearColor()

let highlight = highlights[indexPath.row]

// Format date
let dateFormatter = NSDateFormatter()
dateFormatter.dateFormat = readerConfig.localizedHighlightsDateFormat
let dateString = dateFormatter.stringFromDate(highlight.date)

// Date
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

// Text
let cleanString = highlight.content.stripHtml().truncate(250, trailing: "...").stripLineBreaks()
let text = NSMutableAttributedString(string: cleanString)
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

// Text
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

return cell
}

override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
let highlight = highlights[indexPath.row]

let cleanString = highlight.content.stripHtml().truncate(250, trailing: "...").stripLineBreaks()
let text = NSMutableAttributedString(string: cleanString)
let range = NSRange(location: 0, length: text.length)
let paragraph = NSMutableParagraphStyle()
paragraph.lineSpacing = 3
text.addAttribute(NSParagraphStyleAttributeName, value: paragraph, range: range)
text.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Light", size: 16)!, range: range)

let s = text.boundingRectWithSize(CGSize(width: view.frame.width-40, height: CGFloat.max),
options: [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading],
context: nil)

return s.size.height + 66
}

// MARK: - Table view delegate

override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
let highlight = highlights[indexPath.row]

FolioReader.sharedInstance.readerCenter.changePageWith(page: highlight.page.integerValue, andFragment: highlight.highlightId)

dismissViewControllerAnimated(true, completion: nil)
}

override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
if editingStyle == .Delete {
let highlight = highlights[indexPath.row]

if highlight.page == currentPageNumber {
FRHighlight.removeById(highlight.highlightId) // Remove from HTML
}

Highlight.removeById(highlight.highlightId) // Remove from Core data
highlights.removeAtIndex(indexPath.row)
tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
}
}

// MARK: - Handle rotation transition

override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
tableView.reloadData()
}
}*/
