//  MapBookmarksApp
//
//  Created by Anton Komir on 7/14/16.
//  Copyright © 2016 Anton Komir. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    internal var selectedBookmark: MapBookmark? = nil
    internal var shouldReloadData = false
    internal var shouldCentered = false
    internal var shouldGoTo = false
    
    @IBOutlet weak var MapView: MKMapView!
    let routeLabelText: String = "Route"
    let routeClearLabelText: String = "Clear route"
    let bookmarksLabelText: String = "Bookmarks"
    var mapBookmarks = [MapBookmark]()
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        return managedContext
    }()
    var fetchedResultsController: NSFetchedResultsController!
    let locationManager = CLLocationManager()
    var currentLocation:CLLocation = CLLocation()
    let annotationIdentifier = "annotationIdentifier"
    
    let tableSegue = "SegueToBookmarksTable"
    let detailSegue = "DetailSegue"
    
    var tapLocation: CLLocation? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigation buttons
        self.strandartNavigationBar()
        
        self.addLongPress()
        
        self.loadData()
        
        self.enableCurrentLocation()
    }
    
    func strandartNavigationBar () {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: routeLabelText, style: .Plain, target: self, action: #selector(startRoadRegime))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: bookmarksLabelText, style: .Plain, target: self, action: #selector(goToBookmarksTable))
        
        transparentNavigationBar()
    }
    
    func startRoadRegime () {
        if (self.selectedBookmark != nil) {
            self.showRoad(self.selectedBookmark!)
        }
    }
    
    func goToBookmarksTable () {
        performSegueWithIdentifier(tableSegue, sender: view)
    }
    
    func addLongPress () {
        //adding long press ges
        
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addBookmark(_:)))
        uilgr.minimumPressDuration = 2.0
        
        MapView.addGestureRecognizer(uilgr)
    }
    
    func enableCurrentLocation () {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            MapView.showsUserLocation = true
            MapView.delegate = self
        }
    }
    
    func transparentNavigationBar () {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadData () {
        let fetchRequest = NSFetchRequest(entityName: MapBookmark.entityClass)
        let fetchSort = NSSortDescriptor(key: MapBookmark.titleLabel, ascending: true)
        fetchRequest.sortDescriptors = [fetchSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch let error as NSError {
            print("Unable to perform fetch: \(error.localizedDescription)")
        }
        
        // Get only needed Pins
        
        mapBookmarks = [MapBookmark]()
        
        // Getting area of interest
//        let region:MKCoordinateRegion = MapView.region
//        let maxLatitude = Double(region.center.latitude + region.span.latitudeDelta/2)
//        let maxLongitude = Double(region.center.longitude + region.span.longitudeDelta/2)
//        
//        let minLatitude = Double(region.center.latitude - region.span.latitudeDelta/2)
//        let minLongitude = Double(region.center.longitude - region.span.longitudeDelta/2)
        
        let sectionData = fetchedResultsController.fetchedObjects
        
        // Saving only data in visible area
        
        for mapBookmark in sectionData! {
//            let pinLongitude = Double((mapBookmark as! MapBookmark).longitude!)
//            let pinLatitude = Double((mapBookmark as! MapBookmark).latitude!)
//            
//            if (minLatitude < pinLatitude) && (maxLatitude > pinLatitude) &&
//            (minLongitude < pinLongitude) && (maxLongitude > pinLongitude) {
                mapBookmarks.append(mapBookmark as! MapBookmark)
//            }
        }
        self.drowPins()
    }
    
    func drowPins() {
        // clean all
        
        let annotations = MapView.annotations
        
        for anno : MKAnnotation in annotations {
            MapView.removeAnnotation(anno)
        }
        
        // drow all
        
        for mapBookmark in mapBookmarks {
            let annotation = MKPointAnnotation()
            annotation.title = mapBookmark.title
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(mapBookmark.latitude!),
                                                           longitude: CLLocationDegrees(mapBookmark.longitude!))
            self.MapView.addAnnotation(annotation)
        }
    }
    
    func saveMapBookmark(title: String?, location: CLLocation) {
        let entity =  NSEntityDescription.entityForName(MapBookmark.entityClass, inManagedObjectContext:context)
        
        let mapBookmark = NSManagedObject(entity: entity!,
                                          insertIntoManagedObjectContext: context)
        
        mapBookmark.setValue(title, forKey: MapBookmark.titleLabel)
        mapBookmark.setValue(Double(location.coordinate.longitude), forKey: MapBookmark.longitudeTitle)
        mapBookmark.setValue(Double(location.coordinate.latitude), forKey: MapBookmark.latitudeTitle)
        mapBookmark.setValue(NSDate(), forKey: MapBookmark.dataTitle)
        
        do {
            try context.save()
            //mapBookmarks.append(mapBookmark)
            self.loadData()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func saveMapBookmark(title: String?, latitude: Double, longitude:Double) {
        saveMapBookmark(title, location: CLLocation.init(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude)))
    }
    
    func addBookmark(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(MapView)
            let newCoordinates = MapView.convertPoint(touchPoint, toCoordinateFromView: MapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            self.tapLocation = CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoder failed with error" + error!.localizedDescription)
                    return
                }
            })
            performSegueWithIdentifier(detailSegue, sender: view)
        }
    }
    
    // way
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        CLGeocoder().reverseGeocodeLocation(locations.last!,
//                                            completionHandler: {(placemarks:[CLPlacemark]?, error:NSError?) -> Void in
//                                                if let placemarks = placemarks {
//                                                    let placemark = placemarks[0]
//                                                }
//        })
        let locationArray = locations as NSArray
        currentLocation = locationArray.lastObject as! CLLocation
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }
    
    func showRoad(bookmark:MapBookmark) {
        self.hidePins()
        self.navigationBarRouteRegime()
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(bookmark.latitude!), longitude: CLLocationDegrees(bookmark.longitude!)), addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .Automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            
            for route in unwrappedResponse.routes {
                self.MapView.addOverlay(route.polyline)
                self.MapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func navigationBarRouteRegime () {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: routeClearLabelText, style: .Plain, target: self, action: #selector(clearRoute))
    }
    
    func clearRoute() {
        self.strandartNavigationBar()
        self.MapView.removeOverlays(MapView.overlays)
        loadData()
    }
    
    func hidePins() {
        let annotations = self.MapView.annotations
        for annotation in annotations {
            annotation
            if annotation.coordinate.latitude != selectedBookmark?.latitude &&
                annotation.coordinate.longitude != selectedBookmark?.longitude {
                self.MapView.removeAnnotation(annotation)
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blueColor()
        return renderer
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationIdentifier) as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .InfoLight)
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // find selected bookmark
        for bookmark in mapBookmarks {
            if ((bookmark.latitude!.isEqualToNumber(view.annotation!.coordinate.latitude) && bookmark.longitude!.isEqualToNumber(view.annotation!.coordinate.longitude))) {
                self.selectedBookmark = bookmark
            }
        }
        performSegueWithIdentifier(detailSegue, sender: view)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        for bookmark in mapBookmarks {
            if ((bookmark.latitude!.isEqualToNumber(view.annotation!.coordinate.latitude) && bookmark.longitude!.isEqualToNumber(view.annotation!.coordinate.longitude))) {
                self.selectedBookmark = bookmark
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? BookmarkDetails {
            if (self.tapLocation != nil)
            {
                destination.location = self.tapLocation
                self.tapLocation = nil
            } else {
                destination.bookmark = self.selectedBookmark!
            }
            //navigationController?.addChildViewController(destination)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        transparentNavigationBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        if(shouldCentered) {
//            let center = CLLocationCoordinate2D(latitude: CLLocationDegrees((self.selectedBookmark?.latitude)!), longitude: CLLocationDegrees((self.selectedBookmark?.longitude)!))
//            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//            
//            self.MapView.setRegion(region, animated: true)
//
            MapView.centerCoordinate.latitude = CLLocationDegrees((self.selectedBookmark?.latitude)!)
            MapView.centerCoordinate.longitude = CLLocationDegrees((self.selectedBookmark?.longitude)!)
        }
        if(shouldGoTo) {
            showRoad(self.selectedBookmark!)
        }
        if(shouldReloadData) {
            loadData()
        }
    }
}
