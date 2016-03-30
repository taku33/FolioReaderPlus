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
    private var html:String?  //bodyHtml
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        //とりあえず本全体(全文検索?)ではなく章単位での検索にする
        self.html = FolioReader.sharedInstance.readerCenter.currentPage.getHTML()  //getHTMLBody()
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
        
        //機能追加: 何度も検索を可能にする、キーボードを隠せて下の方の検索結果も見えるように
        
        let pattern = "([a-zA-Z0-9]|.){0,10}\(search!.text!)([a-zA-Z0-9]|.){0,10}"  //それぞれの前後の文字列も確保?
        //"\(search!.text!)"
        
        print("patternは \(pattern)")
      
        self.matches =  RegExp(pattern).matches(self.html!)  //bodyHtml!
        print("matchesは\(self.matches)")
        
        if(self.matches != nil){
            
            for i in 0 ..< self.matches!.count {
                self.matchesStrArray.append( (self.html! as NSString).substringWithRange(self.matches![i].range) )
            }
            /*
            let matchCount = self.matches!.count
            for i in 0 ..< matchCount {
                
                let matchHtmlStr = (self.bodyHtml! as NSString).substringWithRange(self.matches![i].range)
                let matchStr = self.stripTagsFromStr(matchHtmlStr)
                print("タグを抜いたmatchStrは\(matchStr)")
                
                if matchStr.containsString("\(search!.text!)") {
                    //tableに表示
                    self.matchesStrArray.append( matchHtmlStr )
                    
                }else{
                    //tableに表示させない
                    self.matches?.removeAtIndex(i)  //1字違いが起きない？
                }
            }*/
           
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
    
    //機能追加:検索後の行移動し、画面タップでハイライト消すのは uiviewを一時生成してbegantouchで実行？
    
    
    
    
    func stripTagsFromStr(var htmlStr:String)-> String {
        
        print("最初のhtmlStrは\(htmlStr)")
        
        let thescanner = NSScanner(string: htmlStr)
        thescanner.charactersToBeSkipped = nil
        var text:NSString? = nil;
        while (thescanner.atEnd == false) {
         
            if(thescanner.scanUpToString("<", intoString: nil) == true){  // "<"が存在した場合
             
                if(thescanner.scanUpToString(">", intoString: &text) == true){
            
                    
                }else{
                    thescanner.scanUpToString("\(htmlStr.characters.last)", intoString: &text)
                }
            }else{
                
            }
            //replace the found tag with a space
            //(you can filter multi-spaces out later if you wish)
            if(text != nil){
                htmlStr = htmlStr.stringByReplacingOccurrencesOfString(NSString(format:"%@>", text!) as String , withString: "")
            }
        }
        print("第1段階でのhtmlStrは\(htmlStr)")
        
        let thescanner2 = NSScanner(string: htmlStr)
        thescanner2.charactersToBeSkipped = nil
        var text2:NSString? = nil;
        while (thescanner2.atEnd == false) {
            
            if(thescanner2.scanUpToString(">", intoString: &text2) == true){
            //thescanner2.scanUpToString("<", intoString: &text)
                
                
            
            }else{
                
            }
            
            //replace the found tag with a space
            //(you can filter multi-spaces out later if you wish)
            if(text2 != nil){
                htmlStr = htmlStr.stringByReplacingOccurrencesOfString(NSString(format:"%@>", text2!) as String , withString: "")
            }
        }
        print("第2段階でのhtmlStrは\(htmlStr)")
        
        // Trimmed return
        return htmlStr.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
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
        cell.textLabel?.text = "\(self.matchesStrArray[indexPath.row])"
        
        return cell
    }
    
    /*
    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        print("tappした \(indexPath)")
        
        let item = self.matches![indexPath.row]
        //item.rangeを調整し 検索文字列の部分だけにする
        //まずitemの中での検索文字列の位置を取得
        let itemStr = (self.bodyHtml! as NSString).substringWithRange(item.range)
        let searchTextLocation = (itemStr as NSString).rangeOfString(search!.text!).location
        //その位置の分だけずらす
        let adjustedRange = NSMakeRange(item.range.location + searchTextLocation, search!.text!.characters.count)
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        //searchタグの挿入操作(全てJS側でやってもうまくいきそう)
        //検索文字列の部分だけにハイライトタグを追加する
        //let content = (self.bodyHtml! as NSString).substringWithRange(adjustedRange)
        let searchTagId = "search"
        var bodyHtmls = (self.bodyHtml! as NSString)
        let style = HighlightStyle.classForStyle(2)  //青色
        let tag = "<search id=\"\(searchTagId)\" class=\"\(style)\">\(search!.text!)</search>"
        
        //これを使うと同一文字があると個別に移動できない
        //let range: NSRange = adjustedRange   //bodyHtmls.rangeOfString(content, options: .LiteralSearch)
        if adjustedRange.location != NSNotFound {
            
            bodyHtmls = bodyHtmls.stringByReplacingCharactersInRange(adjustedRange, withString: tag)
            let currentPageNum = FolioReader.sharedInstance.readerCenter.currentPage.pageNumber
            let resource = book.spine.spineReferences[currentPageNum-1].resource
            FolioReader.sharedInstance.readerCenter.currentPage.webView.tag = 1  //didfinishLoad時に行移動させるため
            FolioReader.sharedInstance.readerCenter.currentPage.webView.alpha = 0
            
            
            print("bodyHtmlsは\(bodyHtmls)")
            
    
            //大元のhtml全体の<body></body>部分　を新しいものにリプレイス
            
            
            //それを読み込む
            //FolioReader.sharedInstance.readerCenter.currentPage.webView.loadHTMLString(htmls as String, baseURL: NSURL(fileURLWithPath: (resource.fullHref as NSString).stringByDeletingLastPathComponent))
            
            print("bodyHtmls is \(bodyHtmls)")
        }
        else {
            print("item range not found")
        }
    }*/

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


