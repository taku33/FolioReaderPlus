//
//  FolioReaderSearchView.swift
//  Pods
//
//  Created by taku on 2016/03/08.
//
//

import UIKit

class FolioReaderSearchView: UIViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate,UIAlertViewDelegate {
  
    private var search: UISearchBar?
    private var table: UITableView?
    private var barHeight: CGFloat?
    private var displayWidth: CGFloat?
    private var displayHeight: CGFloat?
    private let SEARCHBAR_HEIGHT: CGFloat = 44
    private var adjustedMatches:[NSTextCheckingResult] = []
    private var matchesStrArray:[String] = []
    private var bodyHtml:String?
    private var bodyHtmlArray:[String] = []
    private var pageMappedArray:[Int] = []
    private var tempPage:Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.bodyHtml = FolioReader.sharedInstance.readerCenter.currentPage.getHTMLBody()  //getHTMLBody()
        print("bodyHtmlは. \(self.bodyHtml)")

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
        self.search?.userInteractionEnabled = false  //これしないと、以下全ての実行が2回呼ばれてしまう
        self.showSearchModeAlert()
    }
    
    func searchInThisBook(){
        let pattern = "([a-zA-Z0-9]|.){0,10}\(search!.text!)([a-zA-Z0-9]|.){0,10}"  //それぞれの前後の文字列も確保?
        print("patternは \(pattern)")
        //第1章から順に、章単位で検索(とりあえず各章ずつ表示？→下に引っ張ってリロードでcell追加?) → 結果表示
        for(var j = self.tempPage!; j < FolioReader.sharedInstance.readerCenter.totalPages; j++){
            let indexPath = NSIndexPath(forRow: j, inSection: 0)
            let resource = book.spine.spineReferences[indexPath.row].resource
            let html = try? String(contentsOfFile: resource.fullHref, encoding: NSUTF8StringEncoding)
            //let htmlBody = html!.stringByReplacingOccurrencesOfString("<?xml(.|[\n])*</head>", withString: "", options: .RegularExpressionSearch, range: nil)
            let htmlBodyResult = RegExp("<body>(.|[\n])*</body>").matches(html!)
            let htmlBody = (html! as NSString).substringWithRange(htmlBodyResult![0].range)
            print("htmlBodyは\(htmlBody)")
            self.bodyHtmlArray.append(htmlBody)
    
            var matches =  RegExp(pattern).matches(htmlBody)
            print("matchesは\(matches)")
            if(matches != nil){
                let matchCount = matches!.count
                for i in 0 ..< matchCount {
                    let matchHtmlStr = (htmlBody as NSString).substringWithRange(matches![i].range)
                    let matchStr = self.stripTagsFromStr(matchHtmlStr)
                    print("タグを抜いたmatchStrは\(matchStr)")
                    if matchStr.containsString("\(search!.text!)") {  //大文字、小文字を別々に評価
                        //tableに表示
                        print("firstは \(self.adjustedMatches.first)")
                        if(self.adjustedMatches.first == nil){
                            self.adjustedMatches.append(matches![i])  //insertはダメ
                        }else{
                            self.adjustedMatches.append(matches![i])
                        }
                        self.matchesStrArray.append( matchStr )
                        self.pageMappedArray.append( j )  //これで各cellが何章のものか分かるようにする
                    }else{
                        //tableに表示させない
                    }
                }
                break;  //1章ずつ検索させる為
            }else{
                break;
            }
        }
        
        if(self.matchesStrArray.count > 0){
            if(self.table == nil){
                self.addTable()
            }else{
                self.table!.reloadData()
            }
        }else{
            if(self.tempPage! < FolioReader.sharedInstance.readerCenter.totalPages){
                self.tempPage!++  //次の章を検索させる為
                self.searchInThisBook()
            }else{
                if(self.matchesStrArray.count == 0 ){  //全章内に1つも検索結果がない場合
                    self.showSearchAlert()
                }
            }
        }
    }
    
    func searchInThisChapter(){
        let pattern = "([a-zA-Z0-9]|.){0,10}\(search!.text!)([a-zA-Z0-9]|.){0,10}"
        print("patternは \(pattern)")
        //機能追加: 何度も検索を可能にする
        //機能追加:検索後に画面タップでハイライト消すのは uiviewを一時生成してbegantouchで実行？
        var matches =  RegExp(pattern).matches(self.bodyHtml!)
        print("matchesは\(matches)")
        
        if(matches != nil){
            let matchCount = matches!.count
            for i in 0 ..< matchCount {
                
                let matchHtmlStr = (self.bodyHtml! as NSString).substringWithRange(matches![i].range)
                let matchStr = self.stripTagsFromStr(matchHtmlStr)
                print("タグを抜いたmatchStrは\(matchStr)")
                if matchStr.containsString("\(search!.text!)") {  //大文字、小文字を別々に評価
                    //tableに表示
                    print("firstは \(self.adjustedMatches.first)")
                    if(self.adjustedMatches.first == nil){
                       self.adjustedMatches.append(matches![i])  //insertはダメ
                    }else{
                       self.adjustedMatches.append(matches![i])
                    }
                    self.matchesStrArray.append( matchStr )
                }else{
                    //tableに表示させない
                }
            }
           
            if(self.matchesStrArray.count > 0){
                if(self.table == nil){
                    
                    self.addTable()
                }
            }else{
                self.showSearchAlert()
            }
        }else{
            self.showSearchAlert()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //キーボードを隠す
        self.search?.resignFirstResponder()
        //searchInThisBookの場合
        if(self.tempPage != nil){
            let actualPosition = scrollView.contentOffset.y;
            let contentHeight = scrollView.contentSize.height - (450);  // - (someArbitraryNumber)
            print("actualPosition \(actualPosition)")
            print("contentHeight \(contentHeight)")
            if (actualPosition >= contentHeight) {
                if(self.tempPage! < FolioReader.sharedInstance.readerCenter.totalPages){
                    self.tempPage!++  //次の章を検索させる為
                    self.searchInThisBook()
                    //[self.newsFeedData_ addObjectsFromArray:self.newsFeedData_];
                    //self.table!.reloadData()
                }
            }
        }
    }
    
    func showSearchAlert(){
        let searchAlert = UIAlertView()
        searchAlert.delegate = self
        searchAlert.title = ""
        searchAlert.message = "No Search Result"
        searchAlert.addButtonWithTitle("OK")
        searchAlert.show()
    }

    func showSearchModeAlert(){
        let searchModeAlert = UIAlertView()
        searchModeAlert.delegate = self
        searchModeAlert.title = ""
        searchModeAlert.message = "Search"
        searchModeAlert.addButtonWithTitle("In This Book")
        searchModeAlert.addButtonWithTitle("In This Chapter")
        searchModeAlert.tag = 1
        searchModeAlert.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if(alertView.tag == 1){
            if (buttonIndex == 0) {
                self.tempPage = 0
                self.searchInThisBook()
            } else {
                self.searchInThisChapter()
            }
        }
    }
    
    func stripTagsFromStr(var htmlStr:String)-> String {
        print("最初のhtmlStrは\(htmlStr)")
        //正規表現を使うとシンプルにできる
        htmlStr = htmlStr.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
        print(htmlStr)
        htmlStr = htmlStr.stringByReplacingOccurrencesOfString("<[^>]*", withString: "", options: .RegularExpressionSearch, range: nil)
        print(htmlStr)
        htmlStr = htmlStr.stringByReplacingOccurrencesOfString("[^<]*>", withString: "", options: .RegularExpressionSearch, range: nil)
        print(htmlStr)
        
        return htmlStr.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
        /*let lastChar = htmlStr.characters.last
        if(lastChar == "<"){     //　文字列末尾において、 <　のパターン
            htmlStr.removeAtIndex(htmlStr.endIndex.predecessor())
        }
        htmlStr = NSString(format:"%@%@",htmlStr,"*") as String  //後のスキャンのために*を末尾に追加しておく
        let thescanner = NSScanner(string: htmlStr)
        thescanner.charactersToBeSkipped = nil
        var text:NSString? = nil;
        while (thescanner.atEnd == false) {
            if(thescanner.scanUpToString("<", intoString: nil) == true){  // "<"が存在した場合
                thescanner.scanUpToString("<", intoString: nil)
                if(thescanner.scanUpToString(">", intoString: &text) == true){   //<xxx> のパターン
                    thescanner.scanUpToString(">", intoString: &text)
                    htmlStr = htmlStr.stringByReplacingOccurrencesOfString(NSString(format:"%@>", text!) as String , withString: "")
                }else{          // 文字列末尾において、 <x(1文字以上) のパターン
                        var textt:NSString? = nil;
                        thescanner.scanUpToString("*", intoString: &textt)
                        if(textt != nil){
                            htmlStr = htmlStr.stringByReplacingOccurrencesOfString(NSString(format:"%@",textt!) as String , withString: "")
                        }
                }
                
            }else{
                break;
            }
        }
        htmlStr.removeAtIndex(htmlStr.endIndex.predecessor())  // *を消去
        print("第1段階でのhtmlStrは\(htmlStr)")
        
        let firstChar = String(htmlStr[htmlStr.startIndex.successor()])
        if(firstChar == ">"){
            htmlStr.removeAtIndex(htmlStr.startIndex.successor())
        }
        let thescanner2 = NSScanner(string: htmlStr)
        thescanner2.charactersToBeSkipped = nil
        var text2:NSString? = nil;
        while (thescanner2.atEnd == false) {
            if(thescanner2.scanUpToString(">", intoString: &text2) == true){  // xxx>のパターン
                thescanner2.scanUpToString(">", intoString: &text2)
                if(text2 != nil){
                    htmlStr = htmlStr.stringByReplacingOccurrencesOfString(NSString(format:"%@>", text2!) as String , withString: "")
                }
            }else{
                break;
            }
        }
        print("第2段階でのhtmlStrは\(htmlStr)")
        return htmlStr.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
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
        
        print("カウントは\(self.adjustedMatches.count)")
        return self.adjustedMatches.count
    }
    
    //各セルの要素を設定する
    func tableView(table: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       
        print("indexPath == \(indexPath)")
        // tableCell の ID で UITableViewCell のインスタンスを生成
        let cell = table.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = "\(self.matchesStrArray[indexPath.row])"
        
        return cell
    }
    
    
    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        print("tappした \(indexPath)")
        //In This Book の場合
        if(self.pageMappedArray.count > 0){
            let item = self.adjustedMatches[indexPath.row]
            //item.rangeを調整し 検索文字列の部分だけにする
            //まずitemの中での検索文字列の位置を取得
            let thePage = self.pageMappedArray[indexPath.row]    //thePageは0~
            var bodyHtmls = (self.bodyHtmlArray[thePage] as NSString)
            let itemStr = bodyHtmls.substringWithRange(item.range)
            let searchTextLocation = (itemStr as NSString).rangeOfString(search!.text!).location
            //その位置の分だけずらす
            let adjustedRange = NSMakeRange(item.range.location + searchTextLocation, search!.text!.characters.count)
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
            //searchタグの挿入操作(全てJS側でやってもうまくいきそう)
            //検索文字列の部分だけにハイライトタグを追加する
            //let content = (self.bodyHtml! as NSString).substringWithRange(adjustedRange)
            let searchTagId = "search"
            let style = HighlightStyle.classForStyle(2)  //青色
            let tag = "<search id=\"\(searchTagId)\" class=\"\(style)\">\(search!.text!)</search>"
        
            if adjustedRange.location != NSNotFound {
                bodyHtmls = bodyHtmls.stringByReplacingCharactersInRange(adjustedRange, withString: tag)
                let resource = book.spine.spineReferences[thePage].resource
                FolioReader.sharedInstance.readerCenter.currentPage.webView.tag = 1  //didfinishLoad時に行移動させる為
                FolioReader.sharedInstance.readerCenter.currentPage.webView.alpha = 0
                
                if(FolioReader.sharedInstance.readerCenter.currentPage.pageNumber != thePage + 1){
                    FolioReader.sharedInstance.readerCenter.changePageWith(page: thePage + 1, animated: false, completion: { () -> Void in
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            var html = FolioReader.sharedInstance.readerCenter.currentPage.getHTML()
                            html! = html!.stringByReplacingOccurrencesOfString("<body>(.|[\n])*</body>", withString: bodyHtmls as String, options: .RegularExpressionSearch, range: nil)
                            print("body入れ替え後のhtmlは\(html)")
                            //それ読み込む(これはuiwebviewのメソッド使用)
                            //バグ修正:移動後にテキストハイライトが消えるのを直す
                            FolioReader.sharedInstance.readerCenter.currentPage.webView.loadHTMLString(html! as String, baseURL: NSURL(fileURLWithPath: (resource.fullHref as NSString).stringByDeletingLastPathComponent))
                        }
                    })
                }else{
                    print("その章内なら")
                    var html = FolioReader.sharedInstance.readerCenter.currentPage.getHTML()
                    html! = html!.stringByReplacingOccurrencesOfString("<body>(.|[\n])*</body>", withString: bodyHtmls as String, options: .RegularExpressionSearch, range: nil)
                    FolioReader.sharedInstance.readerCenter.currentPage.webView.loadHTMLString(html! as String, baseURL: NSURL(fileURLWithPath: (resource.fullHref as NSString).stringByDeletingLastPathComponent))
                }
            } else {
                print("item range not found")
            }
        //In This Chapter の場合
        }else{
            let item = self.adjustedMatches[indexPath.row]
            let itemStr = (self.bodyHtml! as NSString).substringWithRange(item.range)
            let searchTextLocation = (itemStr as NSString).rangeOfString(search!.text!).location
            let adjustedRange = NSMakeRange(item.range.location + searchTextLocation, search!.text!.characters.count)
            
            self.dismissViewControllerAnimated(true, completion: nil)
   
            let searchTagId = "search"
            var bodyHtmls = (self.bodyHtml! as NSString)
            let style = HighlightStyle.classForStyle(2)
            let tag = "<search id=\"\(searchTagId)\" class=\"\(style)\">\(search!.text!)</search>"
            
            if adjustedRange.location != NSNotFound {
                bodyHtmls = bodyHtmls.stringByReplacingCharactersInRange(adjustedRange, withString: tag)
                let currentPageNum = FolioReader.sharedInstance.readerCenter.currentPage.pageNumber
                let resource = book.spine.spineReferences[currentPageNum-1].resource
                FolioReader.sharedInstance.readerCenter.currentPage.webView.tag = 1
                FolioReader.sharedInstance.readerCenter.currentPage.webView.alpha = 0
                print("bodyHtmlsは\(bodyHtmls)")
                
                var html = FolioReader.sharedInstance.readerCenter.currentPage.getHTML()
                html! = html!.stringByReplacingOccurrencesOfString("<body>(.|[\n])*</body>", withString: bodyHtmls as String, options: .RegularExpressionSearch, range: nil)
                print("body入れ替え後のhtmlは\(html)")
                FolioReader.sharedInstance.readerCenter.currentPage.webView.loadHTMLString(html! as String, baseURL: NSURL(fileURLWithPath: (resource.fullHref as NSString).stringByDeletingLastPathComponent))
            } else {
                print("item range not found")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


