//
//  CommentViewController.swift
//
//  CommentView that includes a TableView that contains the current post's comments, and a textField to submit your own comments
//  Created by Caitlyn Chen
//

import UIKit
import Bond
import Parse
import ParseUI

class CommentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var commentPosts: [String] = [""]
    var usernames: [String] = [""]
    @IBOutlet weak var tableView: UITableView!
    
    var anno: PinAnnotation?
    var commentBond: Bond<[PFObject]?>!
    
    
    let loginViewController = PFLogInViewController()
    
    var parseLoginHelper: ParseLoginHelper!
    
    let textCellIdentifier = "TextCell"


    @IBOutlet weak var textField: UITextField!
    
    //when user taps back button, returns to PostView
    @IBAction func backButtonTapped(sender: AnyObject) {
        
        self.performSegueWithIdentifier("fromComToPost", sender: nil)
    }
    
    //when user taps sendButton, submit comment to Parse
    @IBAction func sendButton(sender: AnyObject) {
        
        commentPosts = [""]
        usernames = [""]
        
        self.textField.resignFirstResponder()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            
            self.bottomConstraint.constant = 20
            
        })

        if PFUser.currentUser() != nil{
            
            self.anno?.post.commentPost(PFUser.currentUser()!, comment: self.textField.text)
            
        } else{
            
            loginViewController.fields = .UsernameAndPassword | .LogInButton | .SignUpButton | .PasswordForgotten | .DismissButton
            loginViewController.logInView?.backgroundColor = UIColor.blackColor()
            let logo = UIImage(named: "logoforparse")
            let logoView = UIImageView(image: logo)
            loginViewController.logInView?.logo = logoView
            
            loginViewController.signUpController?.signUpView?.backgroundColor = UIColor.blackColor()

            
            loginViewController.signUpController?.signUpView?.logo = logoView
            
            
            parseLoginHelper = ParseLoginHelper {[unowned self] user, error in
                
                if let error = error {
                    
                    ErrorHandling.defaultErrorHandler(error)
                } else  if let user = user {
                    
                    self.loginViewController.dismissViewControllerAnimated(true, completion: nil)
                    
                    self.anno?.post.commentPost(PFUser.currentUser()!, comment: self.textField.text)
                    
                    
                }
            }
            
            loginViewController.delegate = parseLoginHelper
            loginViewController.signUpController?.delegate = parseLoginHelper
            
            
            
            self.presentViewController(loginViewController, animated: true, completion: nil)
            
            
        }
        
        var post = anno?.post
        
        let commentQuery = PFQuery(className: "Comment")
        commentQuery.whereKey("toPost", equalTo: post!)
        
        var comments = commentQuery.findObjects()
        
        if let com = comments {
            for comment in com {
                
                var currentcom = comment as! Comment
                
                currentcom.fromUser?.fetchIfNeeded()
                var user = currentcom.fromUser?.username
                commentPosts.append(currentcom.comment!)
                usernames.append(user!)
                
            }
        }

        tableView.reloadData()
    
        self.textField.text = ""

    
    }
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    //when keyboard shows, textField moves up
    func keyboardWillShow(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            
            self.bottomConstraint.constant = keyboardFrame.size.height + 20
            
        })
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        var post = anno?.post
        
        
        
        //download comments for current Post
        let commentQuery = PFQuery(className: "Comment")
        commentQuery.whereKey("toPost", equalTo: post!)
        
        var comments = commentQuery.findObjects()
        
        if let com = comments {
            for comment in com {
                
                var currentcom = comment as! Comment
                
                currentcom.fromUser?.fetchIfNeeded()
                var user = currentcom.fromUser?.username
                commentPosts.append(currentcom.comment!)
                usernames.append(user!)

                
            }
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.tableView?.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        

    }

    //set number of rows in TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentPosts.count
        
    }
    
    //sets info from Parse to TableView
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as! CustomTableViewCell
        
        let row = indexPath.row
        
        if row == 0{
            
            cell.nameLabel.text = ""
            cell.addressLabel.text = ""
            
        } else {
            
            cell.nameLabel.text = usernames[row]
            cell.addressLabel.text = commentPosts[row]

        }
        
        return cell
        
    }
    

    override func viewDidAppear(animated: Bool) {
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
