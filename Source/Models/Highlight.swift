//
//  Highlight.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 11/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
import CoreData

@objc(Highlight)
class Highlight: NSManagedObject {

    @NSManaged var bookId: String
    @NSManaged var content: String
    @NSManaged var contentPost: String
    @NSManaged var contentPre: String
    @NSManaged var date: NSDate
    @NSManaged var highlightId: String
    @NSManaged var page: NSNumber
    @NSManaged var type: NSNumber?
    @NSManaged var memo: String?

}

public typealias Completion = (error: NSError?) -> ()
let coreDataManager = CoreDataManager()

extension Highlight {
    
    static func persistHighlight(object: FRHighlight, completion: Completion?) {
        var highlight: Highlight?
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Highlight")
            fetchRequest.predicate = NSPredicate(format:"highlightId = %@", object.id)
            highlight = try coreDataManager.managedObjectContext.executeFetchRequest(fetchRequest).last as? Highlight
        } catch let error as NSError {
            print(error)
            highlight = nil
        }
  
        if highlight != nil {
            highlight!.content = object.content
            highlight!.contentPre = object.contentPre
            highlight!.contentPost = object.contentPost
            highlight!.date = object.date
            highlight!.type = object.type.hashValue
        } else {
            highlight = NSEntityDescription.insertNewObjectForEntityForName("Highlight", inManagedObjectContext: coreDataManager.managedObjectContext) as? Highlight
            coreDataManager.saveContext()

            highlight!.bookId = object.bookId
            highlight!.content = object.content
            highlight!.contentPre = object.contentPre
            highlight!.contentPost = object.contentPost
            highlight!.date = NSDate()
            highlight!.highlightId = object.id  //ランダム文字列
            highlight!.page = object.page
            highlight!.type = object.type.hashValue
            //highlight!.memo = nil
        }

        // Save
        do {
            try coreDataManager.managedObjectContext.save()
            if (completion != nil) {
                completion!(error: nil)
            }
        } catch let error as NSError {
            if (completion != nil) {
                completion!(error: error)
            }
        }
    }
    
    static func saveBookMark(object: FRHighlight, completion: Completion?){
        var bookMark: Highlight?
        bookMark = NSEntityDescription.insertNewObjectForEntityForName("Highlight", inManagedObjectContext: coreDataManager.managedObjectContext) as? Highlight
        coreDataManager.saveContext()
        
        bookMark!.bookId = object.bookId
        bookMark!.content = object.content
        bookMark!.contentPre = object.contentPre
        bookMark!.contentPost = object.contentPost
        bookMark!.date = NSDate()
        bookMark!.highlightId = object.id
        bookMark!.page = object.page
        bookMark!.type = nil
        
        // Save
        do {
            try coreDataManager.managedObjectContext.save()
            if (completion != nil) {
                completion!(error: nil)
            }
        } catch let error as NSError {
            if (completion != nil) {
                completion!(error: error)
            }
        }
    }
    
    static func removeById(highlightId: String) {
        var highlight: Highlight?
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Highlight")
            fetchRequest.predicate = NSPredicate(format:"highlightId = %@", highlightId)
            
            highlight = try coreDataManager.managedObjectContext.executeFetchRequest(fetchRequest).last as? Highlight
            coreDataManager.managedObjectContext.deleteObject(highlight!)
            coreDataManager.saveContext()
        } catch let error as NSError {
            print("Error on remove highlight: \(error)")
        }
    }
    
    static func updateHighlightStyleById(highlightId: String, type: HighlightStyle) {
        var highlight: Highlight?
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Highlight")
            fetchRequest.predicate = NSPredicate(format:"highlightId = %@", highlightId)
            
            highlight = try coreDataManager.managedObjectContext.executeFetchRequest(fetchRequest).last as? Highlight
            highlight?.type = type.hashValue
            coreDataManager.saveContext()
        } catch let error as NSError {
            print("Error on update highlightStyle: \(error)")
        }
    }
    
    static func updateMemoById(highlightId: String, newMemo: String) {
        var highlight: Highlight?
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Highlight")
            fetchRequest.predicate = NSPredicate(format:"highlightId = %@", highlightId)
            
            highlight = try coreDataManager.managedObjectContext.executeFetchRequest(fetchRequest).last as? Highlight
            highlight!.memo = newMemo
            coreDataManager.saveContext()
        } catch let error as NSError {
            print("Error on update Memo: \(error)")
        }
    }
    
    static func updateContentPostById(highlightId: String, adjustedContent: String) {  //ページ位置を計算調整したものを更新
        var highlight: Highlight?
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Highlight")
            fetchRequest.predicate = NSPredicate(format:"highlightId = %@", highlightId)
            
            highlight = try coreDataManager.managedObjectContext.executeFetchRequest(fetchRequest).last as? Highlight
            highlight!.contentPost = adjustedContent
            coreDataManager.saveContext()
        } catch let error as NSError {
            print("Error on update ContentPost: \(error)")
        }
    }
    
    static func allByBookId(bookId: String, andPage page: NSNumber? = nil) -> [Highlight] {
        var highlights: [Highlight]?
        let predicate = (page != nil) ? NSPredicate(format: "bookId = %@ && page = %@ && type != nil", bookId, page!) : NSPredicate(format: "bookId = %@", bookId)
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Highlight")
            let sorter: NSSortDescriptor = NSSortDescriptor(key: "date" , ascending: false)
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [sorter]
            
            highlights = try coreDataManager.managedObjectContext.executeFetchRequest(fetchRequest) as? [Highlight]
            return highlights!
        } catch {
            return [Highlight]()
        }
    }
    
    static func allBookMarkByBookId(bookId: String, andPage page: NSNumber? = nil) -> [Highlight] {
        var bookMarks: [Highlight]?
        let predicate = (page != nil) ? NSPredicate(format: "bookId = %@ && page = %@ && type = nil", bookId, page!) : NSPredicate(format: "bookId = %@ && type = nil", bookId)
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Highlight")
            fetchRequest.predicate = predicate
            
            bookMarks = try coreDataManager.managedObjectContext.executeFetchRequest(fetchRequest) as? [Highlight]
            return bookMarks!
        } catch {
            return [Highlight]()
        }
    }
}

