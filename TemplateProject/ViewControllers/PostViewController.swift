//
//  PostViewController.swift
//
//  explores the current post, shows data from Parse
//  Created by Caitlyn Chen
//

import UIKit
import Bond
import Parse
import ParseUI
import FBSDKCoreKit

class PostViewController: UIViewController {
    
    var flagBond: Bond<[PFUser]?>!
    
    
    @IBOutlet weak var dateLabel: UILabel!
    
    var anno: PinAnnotation?
    
    var numOfLikes: Int?
    
    @IBOutlet weak var DescriptionLabel: UILabel!
    @IBOutlet weak var imageViewDisplay: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    var likeBond: Bond<[PFUser]?>!
    
    let loginViewController = PFLogInViewController()
    
    var parseLoginHelper: ParseLoginHelper!
    
    var likList: [PFUser]?
    
    @IBOutlet weak var likeLabel: UILabel!
    
    var login: PFLogInViewController?
    
    //when user taps back button, return to MapView
    @IBAction func backButtonTapped(sender: AnyObject) {
        
        self.performSegueWithIdentifier("backButtonToMap", sender: nil)
    }
    
    //when like button is tapped, check if there is user, then like post
    @IBAction func likeButtonTapped(sender: AnyObject) {
        
        likeButton.selected = true
        
        likeLabel.text = PFUser.currentUser()?.username

//        if PFUser.currentUser() != nil{
//            
//  
//            anno?.post.toggleLikePost(PFUser.currentUser()!)
//            
//            
//            
//        } else{
//
//            loginViewController.fields = .UsernameAndPassword | .LogInButton | .SignUpButton | .PasswordForgotten | .DismissButton            
//            loginViewController.logInView?.backgroundColor = UIColor.blackColor()
//            let logo = UIImage(named: "logoforparse")
//            let logoView = UIImageView(image: logo)
//            loginViewController.logInView?.logo = logoView
//            
//            loginViewController.signUpController?.signUpView?.backgroundColor = UIColor.blackColor()
//
//            
//            loginViewController.signUpController?.signUpView?.logo = logoView
//
//            
//            parseLoginHelper = ParseLoginHelper {[unowned self] user, error in
//              
//                if let error = error {
//                    
//                    ErrorHandling.defaultErrorHandler(error)
//                } else  if let user = user {
//                    
//                    self.loginViewController.dismissViewControllerAnimated(true, completion: nil)
//                    
//                    self.anno?.post.toggleLikePost(PFUser.currentUser()!)
//                    
//                    
//                }
//            }
//            
//            loginViewController.delegate = parseLoginHelper
//            loginViewController.signUpController?.delegate = parseLoginHelper
//            
//            
//            
//            self.presentViewController(loginViewController, animated: true, completion: nil)
//            
//            
//        }
//        
//        if(PFUser.currentUser() != nil){
//            self.anno?.post.toggleLikePost(PFUser.currentUser()!)
//
//        }
    }
    
    //bond for likes
    var post: Post? {
        didSet {
            // free memory of image stored with post that is no longer displayed
            // 1
            if let oldValue = oldValue where oldValue != post {
                // 2
                likeBond.unbindAll()
                imageViewDisplay.designatedBond.unbindAll()
                // 3
                if (oldValue.image.bonds.count == 0) {
                    oldValue.image.value = nil
                }
            }
            
            if let post = post  {
                if likeButton != nil {
                    // bind the image of the post to the 'postImage' view
                    // bind the likeBond that we defined earlier, to update like label and button when likes change
                    post.likes ->> likeBond
                }
            }
        }
    }
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
        likeBond = Bond<[PFUser]?>() { [unowned self] likeList in
            if let likeList = likeList {
                
                self.likeLabel.text = self.stringFromUserList(likeList)
                
                if PFUser.currentUser() != nil{
                    self.likeButton.selected = contains(likeList, PFUser.currentUser()!)
                    
                }
            } else {
                
                self.likeLabel.text = ""
                self.likeButton.selected = false
            }
        }
    }
    
    func stringFromUserList(userList: [PFUser]) -> String {
        // 1
        let usernameList = userList.map { user in user.username! }
        // 2
        let commaSeparatedUserList = ", ".join(usernameList)
        
        if usernameList.count < 4 {
            
            return commaSeparatedUserList
        } else {
            var string = "\(usernameList.count)"
            return string
        }
    }
    
    //upload bond for flags
    func flagBondz (){
        anno?.post.fetchFlags()
        
        var flags = anno?.post.flags
        
        
       flagBond = Bond<[PFUser]?>() { [unowned self] flagList in
            
            if let flagList = flagList {
                if flagList.count > 4 {
                    self.performSegueWithIdentifier("fromPostMap", sender: nil)
                } else {
                    self.performSegueWithIdentifier("fromPostMapForFlagBond", sender: nil)
                }
                
            }
        }
        
        flags! ->> flagBond
        
    }

    //when more button tapped, if user is the postuser, then delete or edit
    //if the current user is not the post user, then flag
    @IBAction func moreButtonTapped(sender: AnyObject) {
        if(PFUser.currentUser()?.username == titleLabel.text){
            let actionSheetController: UIAlertController = UIAlertController()
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            }
            actionSheetController.addAction(cancelAction)
            let takePictureAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Default) { action -> Void in
                let deleteAlert: UIAlertController = UIAlertController(title: "Confirm Deletion", message: "Delete Photo?", preferredStyle: .Alert)
                
                let dontDeleteAction: UIAlertAction = UIAlertAction(title: "Don't Delete", style: .Cancel) { action -> Void in
                }
                deleteAlert.addAction(dontDeleteAction)
                let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Default) { action -> Void in
                    
                    self.performSegueWithIdentifier("fromPostMap", sender: nil)
                    
                }
                deleteAlert.addAction(deleteAction)
                
                
                //Present the AlertController
                self.presentViewController(deleteAlert, animated: true, completion: nil)
            }
            actionSheetController.addAction(takePictureAction)
            let choosePictureAction: UIAlertAction = UIAlertAction(title: "Edit", style: .Default) { action -> Void in
                
                self.performSegueWithIdentifier("editPost", sender: nil)
            }
            actionSheetController.addAction(choosePictureAction)
            
            //We need to provide a popover sourceView when using it on iPad
            actionSheetController.popoverPresentationController?.sourceView = sender as! UIView;
            
            //Present the AlertController
            self.presentViewController(actionSheetController, animated: true, completion: nil)
            
        } else{
            let actionSheetController: UIAlertController = UIAlertController()
            
            //Create and add the Cancel action
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            //Create and add first option action
            let takePictureAction: UIAlertAction = UIAlertAction(title: "Report Inappropriate", style: .Default) { action -> Void in
                let deleteAlert: UIAlertController = UIAlertController(title: "Flag", message: "Are you sure you want to flag this recipe?", preferredStyle: .Alert)
                
                let dontDeleteAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                }
                deleteAlert.addAction(dontDeleteAction)
                let deleteAction: UIAlertAction = UIAlertAction(title: "Flag", style: .Default) { action -> Void in
                    
                    if PFUser.currentUser() != nil{
                        self.anno?.post.flagPost(PFUser.currentUser()!)
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let mapViewController = storyboard.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
                        self.dismissViewControllerAnimated(false, completion: nil)
                        self.presentViewController(mapViewController, animated: true, completion: nil)

                    } else{
                        //login parse viewcontroller
                    self.loginViewController.fields = .UsernameAndPassword | .LogInButton | .SignUpButton | .PasswordForgotten | .DismissButton
                        
                        self.loginViewController.logInView?.backgroundColor = UIColor.blackColor()
                        let logo = UIImage(named: "logoforparse")
                        let logoView = UIImageView(image: logo)
                        self.loginViewController.logInView?.logo = logoView
                        
                        self.loginViewController.signUpController?.signUpView?.backgroundColor = UIColor.blackColor()

                        self.loginViewController.signUpController?.signUpView?.logo = logoView

                        
                        self.parseLoginHelper = ParseLoginHelper {[unowned self] user, error in
                            // Initialize the ParseLogiseguenHelper with a callback
                            println("before the error")
                            if let error = error {
                                // 1
                                ErrorHandling.defaultErrorHandler(error)
                            } else  if let user = user {
                                
                                self.anno?.post.flagPost(PFUser.currentUser()!)
                                
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let mapViewController = storyboard.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
                                self.dismissViewControllerAnimated(false, completion: nil)
                                self.presentViewController(mapViewController, animated: true, completion: nil)

                            }
                        }
                        
                        self.loginViewController.delegate = self.parseLoginHelper
                        self.loginViewController.signUpController?.delegate = self.parseLoginHelper
                        
                        
                        
                        self.presentViewController(self.loginViewController, animated: true, completion: nil)
                        
                        
                    }
                    
                    
                    
                    
                    
                }
                deleteAlert.addAction(deleteAction)
                
                
                //Present the AlertController
                self.presentViewController(deleteAlert, animated: true, completion: nil)
            }
            actionSheetController.addAction(takePictureAction)
            //Create and add a second option action
            
            
            //We need to provide a popover sourceView when using it on iPad
            actionSheetController.popoverPresentationController?.sourceView = sender as! UIView;
            
            //Present the AlertController
            self.presentViewController(actionSheetController, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func unwindToPostView(segue:UIStoryboardSegue) {
        if(segue.identifier == "unwindToPostView"){
            
            
        } else if (segue.identifier == "fromLoginToPostView"){
            
        } else if (segue.identifier == "fromComToPost"){
            
        }
    }
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if let ident = identifier {
            if ident == "toRecipeView" {
                return true
            } else if ident == "toCommentView" {
                return true
            }
            
        }
        
        return false
        
    }
    
    var ing: [String]?
    var ins: [String]?
    
    var image: UIImage?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //post = anno?.post
        DescriptionLabel.text = anno?.Description
        var userfetch = anno?.user.fetchIfNeeded()
        titleLabel.text = anno?.user.username
        
        dateLabel.text = anno?.date.shortTimeAgoSinceDate(NSDate())
        
        
        var data = anno?.image.getData()
        image = UIImage(data: data!)
        
        imageViewDisplay.image = image
        anno?.post.fetchLikes()
        
        if let post = post {
           
            post.likes ->> likeBond
        }
        
        let commentQuery = PFQuery(className: "Like")
        commentQuery.whereKey("toPost", equalTo: post!)
        
        var comments = commentQuery.findObjects()

    
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
   
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "editPost"){
            var dest = segue.destinationViewController as! PostDisplayViewController;
            
            dest.annotation = anno
            
        }
            
            
        else if(segue.identifier == "fromPostMap"){
            
            var dest = segue.destinationViewController as! MapViewController;
            dest.ann = anno
            
            
        } 

        else if (segue.identifier == "fromPostMapForFlagBond"){
            var dest = segue.destinationViewController as! MapViewController;
            dest.annForFlagPost = anno
            
        } else if (segue.identifier == "toCommentView"){
            
            var dest = segue.destinationViewController as! CommentViewController;
            dest.anno = anno!
            
            
        }
    }
    
    
    
}
