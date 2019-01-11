import MapKit
import Foundation
import UIKit
import Parse

//object that stores data from post, allows it to show on Map and PostView and CommentView
class PinAnnotation : NSObject, MKAnnotation {
    
    let coordinate: CLLocationCoordinate2D
    let Description: String
    let image: PFFile
    let user: PFUser
    let date: NSDate
    let post: Post
    let title: String?
    
    
    init (title: String, coordinate: CLLocationCoordinate2D, Description: String, image:PFFile, user: PFUser, date: NSDate, post: Post){
        
        self.title = user.username!
        self.coordinate = coordinate
        self.Description = Description
        self.image = image
        self.user = user
        self.date = date
        self.post = post
        
        
    }
    
}