//
//  Post.swift
//  FBLAFashionFinds
//  Upload info from Post class to Parse backend
//
//  Created by Caitlyn Chen.
//

import Foundation
import Parse
import Bond
import ConvenienceKit

class Post : PFObject, PFSubclassing {
    
    @NSManaged var date: NSDate?
    @NSManaged var caption: String?
    @NSManaged var location: PFGeoPoint?
    
    @NSManaged var imageFile: PFFile?
    @NSManaged var user: PFUser?
    var likes =  Observable<[PFUser]?>(nil)
    var flags =  Observable<[PFUser]?>(nil)
    
    var comments = Observable<[PFObject]?>(nil)

    var image: Observable<UIImage?> = Observable(nil)
    var photoUploadTask: UIBackgroundTaskIdentifier?
    static var imageCache: NSCacheSwift<String, UIImage>!
    
    //upload photo
    func uploadPost() {
        let imageData = UIImageJPEGRepresentation(image.value!, 0.8)
        let imageFile = PFFile(data: imageData!)
        do{
            try imageFile!.save()

        } catch{
            
        }
        
        photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
         
        }
        
        imageFile!.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            // 3
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
        }
        
        user = PFUser.currentUser()
        saveInBackgroundWithBlock(nil)

    }
    
    //download image from parse
    func downloadImage() {
        // 1
        image.value = Post.imageCache[self.imageFile!.name]
        
        if (image.value == nil) {
            
            imageFile?.getDataInBackgroundWithBlock { (data: NSData?, error: NSError?) -> Void in
                if let data = data {
                    let image = UIImage(data: data, scale:1.0)!
                    self.image.value = image
                    // 2
                    Post.imageCache[self.imageFile!.name] = image
                }
            }
        }
    }
    
    //get likes from Parse
//    func fetchLikes() {
//        if (likes.value != nil) {
//            return
//        }
//        
//        ParseHelper.likesForPost(self, completionBlock: { (var likes: [AnyObject]?, error: NSError?) -> Void in
//            likes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
//            
//            self.likes.value = likes?.map { like in
//                let like = like as! PFObject
//                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
//                
//                return fromUser
//            }
//        })
//    }
    
    //get comments from Parse
//    func fetchComments() {
//        if (comments.value != nil) {
//            return
//        }
//        
//        ParseHelper.commentsForPost(self, completionBlock: { (var comments: [AnyObject]?, error: NSError?) -> Void in
//            comments = comments?.filter { comment in comment[ParseHelper.ParseCommentContentFromUser] != nil }
//            
//            self.comments.value = comments?.map { comment in
//                let comment = comment as! PFObject
//                let fromUser = comment[ParseHelper.ParseCommentContentFromUser] as! PFUser
//                let commentMsg = comment[ParseHelper.commentFromUser] as! String
//                
//                return comment
//            }
//        })
//    }
    
    //get flags from Parse
//    func fetchFlags() {
//        // 1
//        if (flags.value != nil) {
//            return
//        }
//        
//        // 2
//        ParseHelper.flagsForPost(self, completionBlock: { (var flag: [AnyObject]?, error: NSError?) -> Void in
//            // 3
//            flag = flag?.filter { like in like[ParseHelper.ParseFlaggedContentFromUser] != nil }
//            
//            // 4
//            self.flags.value = flag?.map { flag in
//                let flag = flag as! PFObject
//                let fromUser = flag[ParseHelper.ParseFlaggedContentFromUser] as! PFUser
//                
//                return fromUser
//            }
//        })
//    }

//    func doesUserLikePost(user: PFUser) -> Bool {
//        if let likes = likes.value {
//            return contains(likes, user)
//        } else {
//            return false
//        }
//    }
//    
//    func toggleLikePost(user: PFUser) {
//        if (doesUserLikePost(user)) {
//            // if image is liked, unlike it now
//            // 1
//            likes.value = likes.value?.filter { $0 != user }
//            ParseHelper.unlikePost(user, post: self)
//        } else {
//            // if this image is not liked yet, like it now
//            // 2
//            likes.value?.append(user)
//            ParseHelper.likePost(user, post: self)
//        }
//    }
    
//    func flagPost(user: PFUser) {
//            
//            flags.value?.append(user)
//            ParseHelper.flagPost(user, post: self)
//    }
//    
    func commentPost(user: PFUser, comment: String) {
        
        comments.value?.append(user)
        ParseHelper.commentPost(user, post: self, comment: comment)
    }
    
    static func parseClassName() -> String {
        return "Post"
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