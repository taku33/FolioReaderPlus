//
//  FolioReaderMemo.swift
//  Pods
//
//  Created by taku on 2016/03/18.
//
//

import UIKit

protocol FolioReaderMemoDelegate{
    func modalDidFinished(modalText: String)
}

class FolioReaderMemo: UIViewController,UITextViewDelegate {
    
    var delegate: FolioReaderMemoDelegate! = nil
    private var myTextView: UITextView?
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTextView = UITextView(frame: CGRectMake(0, 30, self.view.frame.width, self.view.frame.height))
        myTextView!.backgroundColor = isNight(readerConfig.nightModeBackground, UIColor.whiteColor())
        //UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        //print("以前のメモは\(_highlight!.memo)")
        myTextView!.text =  "" //_highlight!.memo
        
        myTextView!.font = UIFont.systemFontOfSize(CGFloat(20))
        myTextView!.textColor = isNight(readerConfig.menuTextColor, UIColor.blackColor())
        myTextView!.textAlignment = NSTextAlignment.Left
        myTextView!.dataDetectorTypes = UIDataDetectorTypes.All //日付や数字の色を変更する
        myTextView!.editable = true;
        myTextView!.delegate = self;
        
        self.view.addSubview(myTextView!)
        myTextView!.becomeFirstResponder()
        
        let keyboadToolbar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.size.width, 50))
        keyboadToolbar.barStyle = UIBarStyle.Default
        keyboadToolbar.items = [
            UIBarButtonItem(title: "✖️", style: UIBarButtonItemStyle.Plain, target: self, action: "closeTapped"),
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "saveMemoTapped")]
        
        keyboadToolbar.sizeToFit()
        myTextView!.inputAccessoryView = keyboadToolbar
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func closeTapped(){
        
        self.dismiss()
    }
    
    func saveMemoTapped(){
        
        print("textは\(myTextView!.text)")
        self.delegate.modalDidFinished(myTextView!.text)
        self.dismiss()
    }
    
    
    //テキストビューが変更された
    func textViewDidChange(textView: UITextView) {
        print("textViewDidChange : \(textView.text)");
    }
    
    // テキストビューにフォーカスが移った
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        print("textViewShouldBeginEditing : \(textView.text)");
        return true
    }
    
    // テキストビューからフォーカスが失われた
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        print("textViewShouldEndEditing : \(textView.text)");
        return true
    }
    
    
}
