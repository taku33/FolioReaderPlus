//
//  FolioReaderPage.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 10/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import SafariServices
import UIMenuItem_CXAImageSupport
import JSQWebViewController

@objc protocol FolioPageDelegate {
    optional func pageDidLoad(page: FolioReaderPage)
}

class FolioReaderPage: UICollectionViewCell, UIWebViewDelegate, UIGestureRecognizerDelegate {
    
    var pageNumber: Int!
    var webView: UIWebView!
    var delegate: FolioPageDelegate!
    var currentScale:CGFloat = 1.0
    private var shouldShowBar = true
    private var menuIsVisible = false
    
    // MARK: - View life cicle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        
        if webView == nil {
            webView = UIWebView(frame: webViewFrame())
            webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            webView.dataDetectorTypes = [.None, .Link]
            webView.scrollView.showsVerticalScrollIndicator = false
            webView.backgroundColor = UIColor.clearColor()
            self.contentView.addSubview(webView)
        }
        webView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        webView.addGestureRecognizer(tapGestureRecognizer)
        
        if readerConfig.allowPageScaling == true {
           
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleDoubleTapGesture:")
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            doubleTapGestureRecognizer.delegate = self
            webView.addGestureRecognizer(doubleTapGestureRecognizer)
            
            let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePinchGesture:")
            pinchGestureRecognizer.delegate = self
            webView.addGestureRecognizer(pinchGestureRecognizer)
            
            tapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
        
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        webView.frame = webViewFrame()  //375,667 など
    }
    
    func webViewFrame() -> CGRect {
        if readerConfig.shouldHideNavigationOnTap == false {
            let statusbarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
            let navBarHeight = FolioReader.sharedInstance.readerCenter.navigationController?.navigationBar.frame.size.height
            let navTotal = statusbarHeight + navBarHeight!
            
            let newFrame = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y+navTotal, width: self.bounds.width, height: self.bounds.height-navTotal)
            return newFrame
        } else {
            return self.bounds
        }
    }
    
    func loadHTMLString(string: String!, baseURL: NSURL!) {
        
        var html = (string as NSString)
        
        // Restore highlights
        let highlights = Highlight.allByBookId((kBookId as NSString).stringByDeletingPathExtension, andPage: pageNumber)
        
        if highlights.count > 0 {
            for item in highlights {
                let style = HighlightStyle.classForStyle(item.type.integerValue)
                let tag = "<highlight id=\"\(item.highlightId)\" onclick=\"callHighlightURL(this);\" class=\"\(style)\">\(item.content)</highlight>"
                let locator = item.contentPre + item.content + item.contentPost
                let range: NSRange = html.rangeOfString(locator, options: .LiteralSearch)
                
                if range.location != NSNotFound {
                    let newRange = NSRange(location: range.location + item.contentPre.characters.count, length: item.content.characters.count)
                    html = html.stringByReplacingCharactersInRange(newRange, withString: tag)
                }
                else {
                    print("highlight range not found")
                }
            }
        }
        
        webView.alpha = 0
        webView.loadHTMLString(html as String, baseURL: baseURL)
    }
    
    // MARK: - UIWebView Delegate
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
        webView.scrollView.contentSize = CGSizeMake(pageWidth, webView.scrollView.contentSize.height) //縦長の1枚に設定
        
        if(FolioReader.sharedInstance.currentBrowseMode == 0 || FolioReader.sharedInstance.currentBrowseMode == 1){  //slide or scroll mode の場合
            
            if scrollDirection == .Down && isScrolling {  //1つ前の章に戻るなら?
                let bottomOffset = CGPointMake(0, webView.scrollView.contentSize.height - webView.scrollView.bounds.height)
                if bottomOffset.y >= 0 {
                    dispatch_async(dispatch_get_main_queue(), {
                        webView.scrollView.setContentOffset(bottomOffset, animated: false)  //1つ前の章の底部分へ移動
                    })
                }
            }
            
            FolioReader.sharedInstance.readerCenter.collectionView.pagingEnabled = true
            FolioReader.sharedInstance.readerCenter.collectionView.scrollEnabled = true
            webView.scrollView.scrollEnabled = true
            
            if(FolioReader.sharedInstance.currentBrowseMode == 0){  //slide mode
                
                webView.scrollView.pagingEnabled = true
                
            }else{  //scroll mode
             
                webView.scrollView.pagingEnabled = false
            }
        }else{
            //simple mode
            //(左タップor右タップで)ページを変更する
            //changepage、文字サイズ等変更 による変化を考慮
            
            FolioReader.sharedInstance.readerCenter.collectionView.pagingEnabled = false
            FolioReader.sharedInstance.readerCenter.collectionView.scrollEnabled = false
            webView.scrollView.scrollEnabled = false
            webView.scrollView.pagingEnabled = false
        }
        
        UIView.animateWithDuration(0.2, animations: {webView.alpha = 1}) { finished in
            webView.isColors = false
            self.webView.createMenu(options: false)
        }
        
        delegate.pageDidLoad!(self)
        
        if(webView.tag == 1){  //検索テーブルをタップして行移動 の場合
            let currentPageNum = FolioReader.sharedInstance.readerCenter.currentPage.pageNumber
            FolioReader.sharedInstance.readerCenter.changePageWith(page: currentPageNum, andFragment: "search") //tag id
            //webView.tag = 0
            
            //ユーザーが画面を何かしらタップしたら(PanGestureも含む)searchタグを削除する→この時ハイライトが消える
        }
        print("webView.tagは\(webView.tag)")
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let url = request.URL
        
        if url?.scheme == "highlight" {
            
            shouldShowBar = false
            
            let decoded = url?.absoluteString.stringByRemovingPercentEncoding as String!
            let rect = CGRectFromString(decoded.substringFromIndex(decoded.startIndex.advancedBy(12)))
            
            webView.createMenu(options: true)
            webView.setMenuVisible(true, andRect: rect)
            menuIsVisible = true
            
            return false
        } else if url?.scheme == "play-audio" {

            let decoded = url?.absoluteString.stringByRemovingPercentEncoding as String!
            let playID = decoded.substringFromIndex(decoded.startIndex.advancedBy(13))

            FolioReader.sharedInstance.readerCenter.playAudio(playID)

            return false
        } else if url?.scheme == "file" {
            
            let anchorFromURL = url?.fragment
            
            // Handle internal url
            if (url!.path! as NSString).pathExtension != "" {
                let base = (book.opfResource.href as NSString).stringByDeletingLastPathComponent
                let path = url?.path
                let splitedPath = path!.componentsSeparatedByString(base.isEmpty ? kBookId : base)
                
                // Return to avoid crash
                if splitedPath.count <= 1 || splitedPath[1].isEmpty {
                    return true
                }
                
                let href = splitedPath[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "/"))
                let hrefPage = FolioReader.sharedInstance.readerCenter.findPageByHref(href)+1
                
                if hrefPage == pageNumber {
                    // Handle internal #anchor
                    if anchorFromURL != nil {
                        handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animating: true)
                        return false
                    }
                } else {
                    
                    print("hrefは..\(href)")
                    //その章に移動
                    FolioReader.sharedInstance.readerCenter.changePageWith(href: href, animated: true)
                }
                
                return false
            }
            
            // Handle internal #anchor
            if anchorFromURL != nil {
                handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animating: true)
                return false
            }
            
            return true
        } else if url?.scheme == "mailto" {
            print("Email")
            return true
        } else if request.URL!.absoluteString != "about:blank" && navigationType == .LinkClicked {
            
            if #available(iOS 9.0, *) {
                let safariVC = SFSafariViewController(URL: request.URL!)
                safariVC.view.tintColor = readerConfig.tintColor
                FolioReader.sharedInstance.readerCenter.presentViewController(safariVC, animated: true, completion: nil)
            } else {
                let webViewController = WebViewController(url: request.URL!)
                let nav = UINavigationController(rootViewController: webViewController)
                nav.view.tintColor = readerConfig.tintColor
                FolioReader.sharedInstance.readerCenter.presentViewController(nav, animated: true, completion: nil)
            }
            
            return false
        }
        
        return true
    }

    func getHTML()-> String? {
        
        let html = self.webView.js("getHTML()")
   
        return html
    }
    
    func getHTMLBody()-> String? {
        
        let htmlBody = self.webView.js("getHTMLBody()")
        
        return htmlBody
    }
    
    // MARK: Gesture recognizer
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer.view is UIWebView {
            if otherGestureRecognizer is UILongPressGestureRecognizer {
                if UIMenuController.sharedMenuController().menuVisible {
                    webView.setMenuVisible(false)
                }
                return false
            }
            return true
        }
        return false
    }
    
    func handleTapGesture(recognizer: UITapGestureRecognizer) {
//        webView.setMenuVisible(false)
        
        if(webView.tag == 1){
            FRHighlight.removeById("search") // Remove from HTML
            webView.tag = 0  //後への影響を無くすため元に戻す
        }
        
        let touchedPoint:CGPoint = recognizer.locationOfTouch(0, inView: self)
        
        if(touchedPoint.x < webView.frame.width/3){  //左タップ
            
            if(FolioReader.sharedInstance.currentBrowseMode == 2){  //simple browse modeの場合
                handleSimpleBrowsePrevious()
            }
            
        }else if(webView.frame.width/3 <= touchedPoint.x  &&  touchedPoint.x <= webView.frame.width*2/3){  //真ん中タップ
            
            if FolioReader.sharedInstance.readerCenter.navigationController!.navigationBarHidden {
                let menuIsVisibleRef = menuIsVisible
                
                let selected = webView.js("getSelectedText()")
                
                if selected == nil || selected!.characters.count == 0 {
                    let seconds = 0.4
                    let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                    
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        
                        if self.shouldShowBar && !menuIsVisibleRef {
                            FolioReader.sharedInstance.readerCenter.toggleBars()
                        }
                        self.shouldShowBar = true
                    })
                }
            } else if readerConfig.shouldHideNavigationOnTap == true {
                FolioReader.sharedInstance.readerCenter.hideBars()
            }
            
            // Reset menu
            menuIsVisible = false
            
        }else{   //右タップ
            
            if(FolioReader.sharedInstance.currentBrowseMode == 2){  //simple browse modeの場合
                handleSimpleBrowseNext()
            }
        }
    }
    
    func handleDoubleTapGesture(recognizer: UITapGestureRecognizer) {

        print("double tapped")
        if(webView.tag == 1){
            FRHighlight.removeById("search")
            webView.tag = 0
        }
        let reverseNum:CGFloat = 1/self.currentScale
        webView.transform = CGAffineTransformScale(webView.transform, reverseNum, reverseNum);
        self.currentScale = 1.0
    }
    
    func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        
        if(webView.tag == 1){
            FRHighlight.removeById("search")
            webView.tag = 0
        }
        
        var scale: CGFloat = recognizer.scale;
        
        /*if(self.currentScale>2 || self.currentScale<0.5){
        
        }else{*/
        
        self.currentScale = self.currentScale * scale
        
        webView.transform = CGAffineTransformScale(webView.transform, scale, scale);
        recognizer.scale = 1.0;
        //}
        
        /*centerViewController.view.transform
        
        var scale = recognizer.scale
        if self.currentScale > 1.0{
        scale = self.currentScale + (scale - 1.0)
        }
        switch recognizer.state{
        case .Changed:
        let scaleTransform = CGAffineTransformMakeScale(scale, scale)
        let transitionTransform = CGAffineTransformMakeTranslation(self.beforePoint.x, self.beforePoint.y)
        self.transform = CGAffineTransformConcat(scaleTransform, transitionTransform)
        case .Ended , .Cancelled:
        if scale <= 1.0{
        self.currentScale = 1.0
        self.transform = CGAffineTransformIdentity
        }else{
        self.currentScale = scale
        }
        default:
        NSLog("not action")
        }*/
        //}
    }
    
    // MARK: - Scroll positioning
    
    func scrollPageToOffset(offset: String, animating: Bool) {
        let jsCommand = "window.scrollTo(0,\(offset));"    //デフォルトで使用可能なDOM操作
        if animating {
            UIView.animateWithDuration(0.35, animations: {
                self.webView.js(jsCommand)
            })
        } else {
            webView.js(jsCommand)
        }
    }
    
    // anchor は hilight id など。
    func handleAnchor(anchor: String,  avoidBeginningAnchors: Bool, animating: Bool) {
        if !anchor.isEmpty {
            if let offset = getAnchorOffset(anchor) {
                print("offsetは\(offset)")
                
                let isBeginning = CGFloat((offset as NSString).floatValue) > self.frame.height/2
                print("self.frame.heightは\(self.frame.height)")  //スマホ画面サイズ 667?
                
                if !avoidBeginningAnchors {   //章のすぐはじめ辺りの場合も行単位で移動させたいなら
                    scrollPageToOffset(offset, animating: animating)
                } else if avoidBeginningAnchors && isBeginning {
                    scrollPageToOffset(offset, animating: animating)
                }
            }
        }
    }
    
    func getAnchorOffset(anchor: String) -> String? {
        let jsAnchorHandler = "(function() {var target = '\(anchor)';var elem = document.getElementById(target); if (!elem) elem=document.getElementsByName(target)[0];return elem.offsetTop;})();"
        return webView.js(jsAnchorHandler)
    }
    
    func handleSimpleBrowseNext() {
        if(webView.scrollView.contentSize.height > webView.scrollView.contentOffset.y){
            webView.scrollView.contentOffset.y += pageHeight-30  //下部の(minutes、pages left)ラベルの大きさも考慮
        }else{
            let currentIndexPath = FolioReader.sharedInstance.readerCenter.getCurrentIndexPath()
            
            print("totalpagesは\(FolioReader.sharedInstance.readerCenter.totalPages)")
            print("currentIndexPath.rowは\(currentIndexPath.row)")
            
            //collectionview cell(章)を1つ次に進める(あるなら)
            if(FolioReader.sharedInstance.readerCenter.totalPages > currentIndexPath.row+1){
                let nextIndexPath = NSIndexPath(forRow: currentIndexPath.row+1, inSection: 0)
                    FolioReader.sharedInstance.readerCenter.collectionView.scrollToItemAtIndexPath(nextIndexPath, atScrollPosition: .Top, animated: false)
            }
        }
    }
    
    func handleSimpleBrowsePrevious() {
        if(0 < webView.scrollView.contentOffset.y){
            webView.scrollView.contentOffset.y -= pageHeight-30
        }else{
            let currentIndexPath = FolioReader.sharedInstance.readerCenter.getCurrentIndexPath()
            
            //collectionview cell(章)を1つ前に戻す(あるなら)
            if(currentIndexPath.row != 0){
                
                  self.scrollToPreviousCell() { error in
                
                    /*
                    print("1つ前の章の底部分へ移動")
                    let bottomOffset = CGPointMake(0, FolioReader.sharedInstance.readerCenter.currentPage.webView.scrollView.contentSize.height - FolioReader.sharedInstance.readerCenter.currentPage.webView.scrollView.bounds.height)
                    
                    if bottomOffset.y >= 0 {
                      //let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                      //dispatch_after(delayTime, dispatch_get_main_queue()) {
                        print("bottomOffset is \(bottomOffset)")
                        dispatch_async(dispatch_get_main_queue(), {
                            FolioReader.sharedInstance.readerCenter.currentPage.webView.scrollView.setContentOffset(bottomOffset, animated: false)
                        })
                      //}
                    }
                    */
                    
                    return
                }
            }
            
            //バグ修正: pages left、minutesを直す
            
            
        }
    }
    
    /*private func scrollToPreviousCell(completionHandler: (NSError?)->()) {
        scrollToPreviousCellRequest(completionHandler)
    }*/
    
    private func scrollToPreviousCell(completionHandler: (NSError?) -> ()){
        
        let currentIndexPath = FolioReader.sharedInstance.readerCenter.getCurrentIndexPath()
        let previousIndexPath = NSIndexPath(forRow: currentIndexPath.row-1, inSection: 0)
        FolioReader.sharedInstance.readerCenter.collectionView.scrollToItemAtIndexPath(previousIndexPath, atScrollPosition: .Bottom, animated: false)
        
        print("コンプレーションパターン")
        completionHandler(nil)
        
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {

        if UIMenuController.sharedMenuController().menuItems?.count == 0 {
            webView.isColors = false
            webView.createMenu(options: false)
        }
        
        return super.canPerformAction(action, withSender: sender)
    }

    func playAudio(){
        webView.play(nil)
    }

    func audioMarkID(ID: String){
        self.webView.js("audioMarkID('\(book.playbackActiveClass())','\(ID)')");
    }
}

// MARK: - WebView Highlight and share implementation

private var cAssociationKey: UInt8 = 0
private var sAssociationKey: UInt8 = 0

extension UIWebView {
    
    var isColors: Bool {
        get { return objc_getAssociatedObject(self, &cAssociationKey) as? Bool ?? false }
        set(newValue) {
            objc_setAssociatedObject(self, &cAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var isShare: Bool {
        get { return objc_getAssociatedObject(self, &sAssociationKey) as? Bool ?? false }
        set(newValue) {
            objc_setAssociatedObject(self, &sAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {

        // menu on existing highlight
        if isShare {
            if action == "colors:" || (action == "share:" && readerConfig.allowSharing == true) || action == "remove:" {
                return true
            }
            return false

        // menu for selecting highlight color
        } else if isColors {
            if action == "setYellow:" || action == "setGreen:" || action == "setBlue:" || action == "setPink:" || action == "setUnderline:" {
                return true
            }
            return false

        // default menu
        } else {
            
            if action == "highlight:"
            || (action == "define:" && (js("getSelectedText()"))!.componentsSeparatedByString(" ").count == 1)
            || (action == "play:" && book.hasAudio() )
            || (action == "share:" && readerConfig.allowSharing == true)
            || (action == "copy:" && readerConfig.allowSharing == true) {
                return true
            }
            return false
        }
    }
    
    public override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func share(sender: UIMenuController) {
        
        if isShare {
            if let textToShare = js("getHighlightContent()") {
                FolioReader.sharedInstance.readerCenter.shareHighlight(textToShare, rect: sender.menuFrame)
            }
        } else {
            if let textToShare = js("getSelectedText()") {
                FolioReader.sharedInstance.readerCenter.shareHighlight(textToShare, rect: sender.menuFrame)
            }
        }
        
        setMenuVisible(false)
    }
    
    func colors(sender: UIMenuController?) {
        isColors = true
        createMenu(options: false)
        setMenuVisible(true)
    }
    
    func remove(sender: UIMenuController?) {
        if let removedId = js("removeThisHighlight()") {
            Highlight.removeById(removedId)
        }
        
        setMenuVisible(false)
    }
    
    func highlight(sender: UIMenuController?) {
        print("highlit tapped")
        if(FolioReader.sharedInstance.readerCenter.currentPage.webView.tag == 1){
            FRHighlight.removeById("search") // Remove from HTML
            FolioReader.sharedInstance.readerCenter.currentPage.webView.tag = 0
        }
        
        let highlightAndReturn = js("highlightString('\(HighlightStyle.classForStyle(FolioReader.sharedInstance.currentHighlightStyle))')")
        let jsonData = highlightAndReturn?.dataUsingEncoding(NSUTF8StringEncoding)
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: []) as! NSArray
            let dic = json.firstObject as! [String: String]
            
            print("dicは\(dic)")
            
            let rect = CGRectFromString(dic["rect"]!)
            
            // Force remove text selection
            userInteractionEnabled = false
            userInteractionEnabled = true

            createMenu(options: true)
            setMenuVisible(true, andRect: rect)
            
            // Persist
            let html = js("getHTML()")
            
            //htmlの中で特定のハイライトスタイルを検索?
            if let highlight = FRHighlight.matchHighlight(html, andId: dic["id"]!) {  //
                Highlight.persistHighlight(highlight, completion: nil)   //それを投げてDB保存
            }
        } catch {
            print("Could not receive JSON")
        }
    }

    func define(sender: UIMenuController?) {
        let selectedText = js("getSelectedText()")
        
        setMenuVisible(false)
        userInteractionEnabled = false
        userInteractionEnabled = true
        
        let vc = UIReferenceLibraryViewController(term: selectedText! )
        vc.view.tintColor = readerConfig.tintColor
        FolioReader.sharedInstance.readerContainer.showViewController(vc, sender: nil)
    }

    func play(sender: UIMenuController?) {

        js("playAudio()")

        // Force remove text selection
        // @NOTE: this doesn't seem to always work
        userInteractionEnabled = false
        userInteractionEnabled = true
    }


    // MARK: - Set highlight styles
    
    func setYellow(sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .Yellow)
    }
    
    func setGreen(sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .Green)
    }
    
    func setBlue(sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .Blue)
    }
    
    func setPink(sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .Pink)
    }
    
    func setUnderline(sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .Underline)
    }

    func changeHighlightStyle(sender: UIMenuController?, style: HighlightStyle) {
        FolioReader.sharedInstance.currentHighlightStyle = style.rawValue

        if let updateId = js("setHighlightStyle('\(HighlightStyle.classForStyle(style.rawValue))')") {
            Highlight.updateHighlightStyleById(updateId, type: style)
        }
        colors(sender)
    }
    
    // MARK: - Create and show menu
    
    func createMenu(options options: Bool) {
        isShare = options
        
        let colors = UIImage(readerImageNamed: "colors-marker")
        let share = UIImage(readerImageNamed: "share-marker")
        let remove = UIImage(readerImageNamed: "no-marker")
        let yellow = UIImage(readerImageNamed: "yellow-marker")
        let green = UIImage(readerImageNamed: "green-marker")
        let blue = UIImage(readerImageNamed: "blue-marker")
        let pink = UIImage(readerImageNamed: "pink-marker")
        let underline = UIImage(readerImageNamed: "underline-marker")
        
        let highlightItem = UIMenuItem(title: readerConfig.localizedHighlightMenu, action: "highlight:")
        let playAudioItem = UIMenuItem(title: readerConfig.localizedPlayMenu, action: "play:")
        let defineItem = UIMenuItem(title: readerConfig.localizedDefineMenu, action: "define:")
        let colorsItem = UIMenuItem(title: "C", image: colors!, action: "colors:")
        let shareItem = UIMenuItem(title: "S", image: share!, action: "share:")
        let removeItem = UIMenuItem(title: "R", image: remove!, action: "remove:")
        let yellowItem = UIMenuItem(title: "Y", image: yellow!, action: "setYellow:")
        let greenItem = UIMenuItem(title: "G", image: green!, action: "setGreen:")
        let blueItem = UIMenuItem(title: "B", image: blue!, action: "setBlue:")
        let pinkItem = UIMenuItem(title: "P", image: pink!, action: "setPink:")
        let underlineItem = UIMenuItem(title: "U", image: underline!, action: "setUnderline:")
        
        let menuItems = [playAudioItem, highlightItem, defineItem, colorsItem, removeItem, yellowItem, greenItem, blueItem, pinkItem, underlineItem, shareItem]

        UIMenuController.sharedMenuController().menuItems = menuItems
    }
    
    func setMenuVisible(menuVisible: Bool, animated: Bool = true, andRect rect: CGRect = CGRectZero) {
        if !menuVisible && isShare || !menuVisible && isColors {
            isColors = false
            isShare = false
        }
        
        if menuVisible  {
            if !CGRectEqualToRect(rect, CGRectZero) {
                UIMenuController.sharedMenuController().setTargetRect(rect, inView: self)
            }
        }
        
        UIMenuController.sharedMenuController().setMenuVisible(menuVisible, animated: animated)
    }
    
    func js(script: String) -> String? {
        let callback = self.stringByEvaluatingJavaScriptFromString(script)
        if callback!.isEmpty { return nil }
        return callback
    }
}

extension UIMenuItem {
    convenience init(title: String, image: UIImage, action: Selector) {
        self.init(title: title, action: action)
        self.cxa_initWithTitle(title, action: action, image: image, hidesShadow: true)
    }
}
