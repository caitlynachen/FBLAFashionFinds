//
//  MapViewController.swift
//
//  allows users to explore a map with posts of FBLA members from across the world
//  utilizes MapKit
//  Created by Caitlyn Chen
//


import MapKit
import UIKit
import CoreLocation
import Parse
import ParseUI
import Bond
import FBSDKCoreKit
import FBSDKLoginKit

class MapViewController: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, MKMapViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var cancel: UIButton!
    var annotationCurrent: PinAnnotation?
    
    var fromGeoButton: Bool?
    var geoButtonTitle: String?
    
    var fromLoginViewController: Bool = false
    
    var searchController:UISearchController!
    var annotation:MKAnnotation!
    var localSearchRequest:MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    var localSearchResponse:MKLocalSearchResponse!
    var error:NSError!
    var pointAnnotation:MKPointAnnotation!
    var pinAnnotationView:MKPinAnnotationView!
    
    @IBOutlet weak var toolbar: UIToolbar!
    var ann: PinAnnotation?
    var annForFlagPost: PinAnnotation?
    var coorForUpdatedPost: CLLocationCoordinate2D?
    
    var updatedPost: PinAnnotation?
    
    var points: [PFGeoPoint] = []
    
    var locationManager = CLLocationManager()
    let loginViewController = PFLogInViewController()
    var parseLoginHelper: ParseLoginHelper!
    
    var mapAnnoations: [PinAnnotation] = []
    
    
    private var responseData:NSMutableData?
    private var selectedPointAnnotation:MKPointAnnotation?
    private var connection:NSURLConnection?
    
    
    @IBAction func infoButtonTapped(sender: AnyObject) {
        
        self.performSegueWithIdentifier("toInfoView", sender: nil)
    }
    
    @IBAction func unwindToVC(segue:UIStoryboardSegue) {
        if(segue.identifier == "fromPostToMap"){
            
            
        } else if (segue.identifier == "fromPostDiplayToMap") {
            let svc = segue.sourceViewController as! PostDisplayViewController;
            
            if svc.annotation?.post == nil{
                
                svc.createPost()
                
            } else {
                svc.updatePost()
                
                updatedPost = svc.annotation
            }
            
            
            annotationCurrent = svc.currentAnnotation
            
            
        } else if (segue.identifier == "backButtonToMap"){
            print("hello", terminator: "")
        } else if (segue.identifier == "fromInfoToMap"){
            
        }
        
    }
    
    
    
    
    @IBAction func logoutTapped(sender: AnyObject) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "No", style: .Cancel) { action -> Void in
            //Do some stuff
            
        }
        actionSheetController.addAction(cancelAction)
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action -> Void in
            //Do some other stuff
            PFUser.logOut()
            let logoutNotification: UIAlertController = UIAlertController(title: "Logout", message: "Successfully Logged Out!", preferredStyle: .Alert)
            
            
            self.presentViewController(logoutNotification, animated: true, completion: nil)
            logoutNotification.dismissViewControllerAnimated(true, completion: nil)
            self.toolbar.hidden = true
            
        }
        actionSheetController.addAction(nextAction)
        //Add a text field
        
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        //        if let ident = identifier {
        if identifier == "segueToPostDisplay" {
            if PFUser.currentUser() != nil{
                self.dismissViewControllerAnimated(true, completion: nil)
                return true
                
                
            } else {
                
                loginViewController.fields = [PFLogInFields.UsernameAndPassword, PFLogInFields.DismissButton, PFLogInFields.PasswordForgotten, PFLogInFields.LogInButton, PFLogInFields.SignUpButton]
                
                loginViewController.logInView?.backgroundColor = UIColor.blackColor()
                let logo = UIImage(named: "logoforparse")
                let logoView = UIImageView(image: logo)
                loginViewController.logInView?.logo = logoView
                
                loginViewController.signUpController?.signUpView?.backgroundColor = UIColor.blackColor()
                loginViewController.signUpController?.signUpView?.logo = logoView
                
                
                parseLoginHelper = ParseLoginHelper {[unowned self] user, error in
                    // Initialize the ParseLoginHelper with a callback
                    print("before the error")
                    if let error = error {
                        // 1
                        ErrorHandling.defaultErrorHandler(error)
                    } else  if user != nil {
                        // if login was successful, display the TabBarController
                        // 2
                        self.fromLoginViewController = true
                        
                        self.dismissViewControllerAnimated(true, completion: nil)
                        
                        self.fromLoginViewController = true
                        
                        self.performSegueWithIdentifier("segueToPostDisplay", sender: self)
                        
                    }
                    
                }
                
                
                
                loginViewController.delegate = parseLoginHelper
                loginViewController.signUpController?.delegate = parseLoginHelper
                
                
                
                
                self.presentViewController(loginViewController, animated: true, completion: nil)
                
                return false
                
                
            }
        }
        //        }
        
        return false
    }
    
    
    
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if PFUser.currentUser() != nil{
            toolbar.hidden = false
        } else{
            toolbar.hidden = true
        }
        
        print("in MapViewController")
        
        
        
        
        fromLoginViewController = false
        
        locationManager.delegate = self
        mapView.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if annotationCurrent != nil{
            self.mapView.addAnnotation(annotationCurrent!)
            
            let latt = annotationCurrent?.coordinate.latitude
            let longg = annotationCurrent?.coordinate.longitude
            let coordd = CLLocationCoordinate2D(latitude: latt!, longitude: longg!)
            let dumbcoor = CLLocationCoordinate2D(latitude: (latt!) - 1, longitude: (longg!) - 1)
            self.mapView.setCenterCoordinate(dumbcoor, animated: true)
            let span = MKCoordinateSpanMake(0.05, 0.05)
            
            let region = MKCoordinateRegion(center: coordd, span: span)
            
            regionCenter = region.center
            
            mapView.setRegion(region, animated: true)
            
            
        } else if ann != nil {
            do{
                try ann?.post.delete()
            } catch {
                
            }
            
            self.mapView.removeAnnotation(ann!)
            
        } else if updatedPost != nil {
            let latt = updatedPost?.post.location?.latitude
            let longg = updatedPost?.post.location?.longitude
            let coordd = CLLocationCoordinate2D(latitude: latt!, longitude: longg!)
            let dumbcoor = CLLocationCoordinate2D(latitude: (latt!) - 1, longitude: (longg!) - 1)
            self.mapView.setCenterCoordinate(dumbcoor, animated: true)
            let span = MKCoordinateSpanMake(0.05, 0.05)
            
            let region = MKCoordinateRegion(center: coordd, span: span)
            
            regionCenter = region.center
            
            mapView.setRegion(region, animated: true)
            
        }
        
        
        
    }
    
    @IBOutlet weak var navbar: UINavigationBar!
    
    @IBAction func showSearchBar(sender: AnyObject) {
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar){
        //1
        searchBar.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
        
        //2
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.startWithCompletionHandler { (localSearchResponse, error) -> Void in
            
            if localSearchResponse == nil{
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
                return
            }
            //3
            self.pointAnnotation = MKPointAnnotation()
            self.pointAnnotation.title = searchBar.text
            self.pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: localSearchResponse!.boundingRegion.center.latitude, longitude:     localSearchResponse!.boundingRegion.center.longitude)
            
            
            self.pinAnnotationView = MKPinAnnotationView(annotation: self.pointAnnotation, reuseIdentifier: nil)
            self.mapView.centerCoordinate = self.pointAnnotation.coordinate
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error")
    }
    
    override func viewWillAppear(animated: Bool) {
        toolBar()
    }
    func toolBar() {
        if toolbar != nil{
            if PFUser.currentUser() != nil{
                toolbar.hidden = false
            } else{
                toolbar.hidden = true
            }
        }
    }
    
    //var point = PinAnnotation(title: "newPoint", coordinate: currentLocation!)
    var lat: CLLocationDegrees?
    var long: CLLocationDegrees?
    var currentLocation: CLLocationCoordinate2D?
    var regionCenter: CLLocationCoordinate2D?
    var locforPost: CLLocationCoordinate2D?
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if annotationCurrent == nil && updatedPost == nil {
            
            
            let userLocation : CLLocation = locations[0]
            
            self.lat = userLocation.coordinate.latitude
            self.long = userLocation.coordinate.longitude
            
            locforPost = CLLocationCoordinate2DMake(self.lat!, self.long!)
            //self.mapView.addAnnotation(point)
            
            let location = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            
            currentLocation = location
            
            let span = MKCoordinateSpanMake(0.05, 0.05)
            
            let region = MKCoordinateRegion(center: location, span: span)
            
            regionCenter = region.center
            
            mapView.setRegion(region, animated: true)
            
            
        }
        locationManager.stopUpdatingLocation()
        
        
    }
    
    //when users moves map, make the posts from parse that are near current location appear
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let loc = PFGeoPoint(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        
        
        let postsQuery = PFQuery(className: "Post")
        
        postsQuery.whereKey("location", nearGeoPoint: loc, withinMiles: 5.0)
        //finds all posts near current locations
        
        do{
            let posts: [PFObject] = try postsQuery.findObjects()
            
            
            
            for post in posts {
                
                //                println(post.count)
                //                println("posts from parse")
                
                let postcurrent = post as! Post
                //
                //                let flagQuery = PFQuery(className: "FlaggedContent")
                //                flagQuery.whereKey("toPost", equalTo: postcurrent)
                
                //                var flags = flagQuery.findObjects()
                
                //                if flags?.count > 3 {
                //                    postcurrent.delete()
                //                } else{
                
                
                
                //                    if PFUser.currentUser() != nil{
                //
                ////                        let flagQueryForSpecificUser = PFQuery(className: "FlaggedContent")
                ////
                ////
                ////                        flagQueryForSpecificUser.whereKey("fromUser", equalTo: PFUser.currentUser()!)
                ////                        flagQueryForSpecificUser.whereKey("toPost", equalTo: postcurrent)
                ////
                ////                        var flagForSpecificUser = flagQueryForSpecificUser.findObjects()
                ////
                ////                        if flagForSpecificUser?.count > 0 {
                ////
                //                        } else {
                if (postcurrent.imageFile != nil && postcurrent.location != nil && postcurrent.caption != nil && postcurrent.user != nil && postcurrent.date != nil ){
                    print(" make stuff")
                    let lati = postcurrent.location!.latitude
                    let longi = postcurrent.location!.longitude
                    let coor = CLLocationCoordinate2D(latitude: lati, longitude: longi)
                    
                    var annotationParseQuery = PinAnnotation?()
                    
                    do{
                        _ = try postcurrent.user!.fetchIfNeeded()
                    } catch{
                        
                    }
                    
                    let name = postcurrent.user?.username
                    
                    
                    annotationParseQuery = PinAnnotation(title: name!, coordinate: coor, Description: postcurrent.caption!, image: postcurrent.imageFile!, user: postcurrent.user!, date: postcurrent.date!, post: postcurrent)
                    
                    
                    //self.mapAnnoations.append(annotationcurrent!)
                    //println("append")
                    
                    //for anno in mapAnnoations {
                    self.mapView.addAnnotation(annotationParseQuery!)
                    print("addanno")
                    
                }
            }
            
            //                    } else {
            //
            //                        if (postcurrent.imageFile != nil && postcurrent.location != nil && postcurrent.caption != nil && postcurrent.user != nil && postcurrent.date != nil ){
            ////                            println(" make stuff")
            //                            let lati = postcurrent.location!.latitude
            //                            let longi = postcurrent.location!.longitude
            //                            let coor = CLLocationCoordinate2D(latitude: lati, longitude: longi)
            //
            //                            var annotationParseQuery = PinAnnotation?()
            //
            //                            var userfetch = postcurrent.user!.fetchIfNeeded()
            //                            var name = postcurrent.user?.username
            //
            //                            annotationParseQuery = PinAnnotation(title: name!, coordinate: coor, Description: postcurrent.caption!, image: postcurrent.imageFile!, user: postcurrent.user!, date: postcurrent.date!, post: postcurrent)
            //
            //
            //                            //self.mapAnnoations.append(annotationcurrent!)
            //                            //println("append")
            //                            //for anno in mapAnnoations {
            //                            self.mapView.addAnnotation(annotationParseQuery!)
            ////                            tln                            print("addanno")
            //
            //                        }
            
        }  catch{
            
        }
        
        
        
    }
    
    //customize annotation view
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        //        var view: MKAnnotationView?
        
        if annotation is MKUserLocation{
            return nil
        } else if !(annotation is PinAnnotation) {
            return nil
        }
        
        //        var anView: MKAnnotaionView?
        
        var anView: MKAnnotationView?
        
        if fromTxtField == false{
            
            let identifier = "postsFromParseAnnotations"
            
            anView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            if anView == nil{
                
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                anView!.canShowCallout = true
            }
                
            else {
                
                anView!.annotation = annotation
                
            }
            
            
            
            
            let pinanno = annotation as! PinAnnotation
            //            do{
            //                if pinanno.image.getData(){
            do{
                let data: NSData = try pinanno.image.getData()
                
                let size = CGSize(width: 30.0, height: 30.0)
                
                let imagee = UIImage(data: data)
                let scaledImage = imageResize(imagee!, sizeChange: size)
                anView!.image = scaledImage
                anView?.layer.borderColor = UIColor.whiteColor().CGColor
                anView?.layer.borderWidth = 1
                
            } catch{
                
            }
            
//            let playButton  = UIButton(type: .Custom)
//            if let image = UIImage(named: "info") {
//                playButton.setImage(image, forState: .Normal)
//            }
            
            anView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            
            

            
            
            
            //                }
            //            } catch{
            //
            //            }
            //            if (pinanno.image.getData() != nil){
            
            
            
            //            }
            
            // }
            
        }
        
        return anView
    }
    
    
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? PinAnnotation {
            
            performSegueWithIdentifier("toPostView", sender: annotation)
        }
    }
    
    var coordinateAfterPosted: CLLocationCoordinate2D?
    
    
    
    //    func addPostedAnnotation (){
    //        self.mapView.addAnnotation(annotationCurrent)
    //
    //    }
    
    
    //MARK: NSURLConnectionDelegate
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        responseData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        responseData?.appendData(data)
    }
    
    
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        print("Error: \(error.localizedDescription)")
    }
    
    var fromTxtField: Bool = false
    //MARK: Map Utilities
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueToPostDisplay") {
            let svc = segue.destinationViewController as! PostDisplayViewController;
            
            annotationCurrent = nil
            updatedPost = nil
            if (lat == nil && long == nil){
                lat = 37.40549
                long = -121.977655
            }
            
            svc.toLoc = PFGeoPoint(latitude: lat!, longitude: long!)
        }
        
        if (segue.identifier == "toPostView"){
            let annotation = sender as! PinAnnotation
            
            let svc = segue.destinationViewController as! PostViewController;
            svc.anno = annotation
            svc.post = annotation.post
            svc.login = loginViewController
        }
    }
    
    
}
