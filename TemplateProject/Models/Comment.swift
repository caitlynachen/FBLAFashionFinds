//
//  Comment.swift
//  GeoRecipe
//
//  Created by Caitlyn Chen.
//


import Foundation
import Parse
import Bond
import ConvenienceKit

import UIKit

// upload info for Comment class to Parse
class Comment: PFObject, PFSubclassing {
    
    @NSManaged var comment: String?
    @NSManaged var fromUser: PFUser?
    
    static func parseClassName() -> String {
        return "Comment"
    }
    
    override init () {
        super.init()
    }
    
    override class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            self.registerSubclass()
            Post.imageCache = NSCacheSwift<String, UIImage>()
        }
    }
   
}
