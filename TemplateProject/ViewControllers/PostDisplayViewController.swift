//
//  PostDisplayViewController.swift
//
//  view controller that allows user to create a post and upload it to Parse backend
//  Created by Caitlyn Chen
//

import UIKit
import Parse
import MapKit
import Bond
import FBSDKCoreKit
import CoreLocation

class PostDisplayViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate, UITextViewDelegate, UITextFieldDelegate{
    
    @IBOutlet weak var navbar: UINavigationBar!
    
    @IBOutlet weak var emptyLabel: UILabel!
    
    var photoTakingHelper: PhotoTakingHelper?
    
    @IBOutlet weak var imageView: UIImageView?
    //    @IBOutlet weak var instructionTableView: UITableView!
    @IBOutlet weak var descriptionText: UITextView!
    //    @IBOutlet weak var ingredientsTableView: UITableView!
    @IBOutlet weak var postButton: UIButton!
    
    var locationLabelFromPostDisplay: String?
    
    let post = Post()
    
    var toLoc: PFGeoPoint?
    var image: UIImage?
    var annotation: PinAnnotation?
    @IBOutlet weak var cameraButton: UIButton!
    
    var placeholderLabel: UILabel!

    //backbutton allows user to return to MapView
    @IBAction func backButton(sender: AnyObject) {
        
        let actionSheetController: UIAlertController = UIAlertController(title: "Cancel", message: "Are you sure you want to cancel?", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mapViewController = storyboard.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
            self.dismissViewControllerAnimated(false, completion: nil)
            self.presentViewController(mapViewController, animated: true, completion: nil)
            mapViewController.viewDidAppear(true)
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Continue", style: .Default) { action -> Void in
            //Do some other stuff
        }
        actionSheetController.addAction(nextAction)
        //Add a text field
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    
    //clears all textViews, imageViews when post is created
    func clearEverything(){
        
        navbar.topItem?.title = "Create a Post"

        descriptionText.text = ""
        imageView?.image = nil
        cameraButton.hidden = false
        
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if let ident = identifier {
            if ident == "fromPostDiplayToMap" {
                if imageView?.image == nil {
                    emptyLabel.text = "Please add an image."
                    emptyLabel.hidden = false
                    
                } else {
                    return true
                }
            } else if ident == "PresentEditLocationScene" {
                
                return true

            }
        }
        
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }
    
    //when camera button is tapped, use photoTakingHelper to choose photo
    @IBAction func cameraButtonTapped(sender: AnyObject) {
        //println("hi")
        photoTakingHelper =
            PhotoTakingHelper(viewController: self) { (image: UIImage?) in
                // 1
                
                self.post.image.value = image!
                
                self.imageView?.image = image!
                
                let imageData = UIImageJPEGRepresentation(image, 0.8)
                let imageFile = PFFile(data: imageData)
                //imageFile.save()
                
                //let post = PFObject(className: "Post")
                if self.annotation == nil {
                    self.post["imageFile"] = imageFile
                    self.post.save()
                    
                } else {
                    let imageData = UIImageJPEGRepresentation(self.imageView?.image, 0.8)
                    let imageFile = PFFile(data: imageData)
                    
                    self.annotation?.post.imageFile = imageFile
                    self.annotation?.post.imageFile?.save()
                    
                }
                
                self.cameraButton.hidden = true
        }
        
    }
    
       func textViewDidChange(textView: UITextView) {
        if textView == descriptionText{
            placeholderLabel.hidden = count(textView.text) != 0
            
        }
    }
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        descriptionText.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyLabel.hidden = true
        
        imageView!.layer.borderWidth = 0.5
        imageView!.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2).CGColor
        imageView!.layer.cornerRadius = 5
        
        
        //picker = UIPickerView(2
        

        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        self.view!.addGestureRecognizer(tap)
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        
        descriptionText.delegate = self
        placeholderLabel = UILabel()
        placeholderLabel.text = "Write a caption..."
        placeholderLabel.sizeToFit()
        descriptionText.addSubview(placeholderLabel)
        
        placeholderLabel.frame.origin = CGPointMake(5, descriptionText.font.pointSize / 2)
        placeholderLabel.font = UIFont(name: placeholderLabel.font.fontName, size: 12)
        placeholderLabel.textColor = UIColor(white: 0, alpha: 0.2)
        placeholderLabel.hidden = count(descriptionText.text) != 0
        
        
        if annotation?.post != nil{
            var data = annotation?.image.getData()
            image = UIImage(data: data!)
            imageView?.image = image
            
            
        }
        
        
        if (annotation?.Description != nil && annotation?.image != nil) {
            
            navbar.topItem?.title = "Edit Post"
            
            descriptionText.text = annotation?.Description
            
            placeholderLabel.hidden = count(descriptionText.text) != 0
            
            
        }
        
        
    }
    
 
    
    var coordinateh: CLLocationCoordinate2D?
    
    var pfgeopoint: PFGeoPoint?
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func dismissKeyboard() {
        descriptionText.resignFirstResponder()
    }
    
    var currentAnnotation: PinAnnotation?
        
    
    func updatePost() {
        
        //change parse info
        
        
        annotation?.post.caption = descriptionText.text
        
        
        annotation?.post.save()
        annotation?.post.saveInBackgroundWithBlock(nil)
        
        
    }
    
    //create a new post in Parse
    func createPost(){
        
        if pfgeopoint == nil {
            pfgeopoint = toLoc
        }
        
        post.caption = descriptionText.text
        post.location = pfgeopoint
        post.date = NSDate()
      
        if imageView?.image == nil {
            emptyLabel.text = "Please add an image."
            emptyLabel.hidden = false
            
        } else {
            
            post.save()
            post.uploadPost()
        }

        
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapViewController = storyboard.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
        

      
        if coordinateh == nil{
            var latitu = toLoc?.latitude
            var longit = toLoc?.longitude
            
            coordinateh = CLLocationCoordinate2DMake(latitu!, longit!)
        }
        
        var name = post.user?.username
        var annotationToAdd = PinAnnotation(title: name!, coordinate: coordinateh!, Description: post.caption!, image: post.imageFile!, user: post.user!, date: post.date!, post: post)
        
        currentAnnotation = annotationToAdd
        
        
    }
    
}
