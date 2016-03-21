//
//  RegExp.swift
//  Pods
//
//  Created by taku on 2016/03/16.
//
//

import Foundation

class RegExp {
    let internalRegexp: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalRegexp = try! NSRegularExpression( pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive)
    }
    
    func isMatch(input: String) -> Bool {
        let matches = self.internalRegexp.matchesInString( input, options: [], range:NSMakeRange(0, input.characters.count) )
        return matches.count > 0
    }
    
    func matches(input: String) -> [NSTextCheckingResult]? {
        if self.isMatch(input) {   //マッチがあるなら
            let matches = self.internalRegexp.matchesInString( input, options: [], range:NSMakeRange(0, input.characters.count) )
            return matches
            
            /*var results: [String] = []
            for i in 0 ..< matches.count {
                results.append( (input as NSString).substringWithRange(matches[i].range) )
            }
            return results*/
        }
        return nil
    }
}


/* 使い方
let pattern = "http://([a-zA-Z0-9]|.)+"
let str:String = "銘柄コード:1557,銘柄名:SPDR S&P500 ETF TRUST板価格:25270.0,板数量:10000にいびつな板(寄与率:81.20178%)を検出しました。http://oreore.com/servlets/Action?SRC=1234"
Regexp(pattern).isMatch(str) //マッチした結果　ここではtrue
let ret:[String] = Regexp(pattern).matches(str)! //http以下を取得
*/




