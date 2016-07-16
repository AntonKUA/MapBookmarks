//
//  BookmarkDetails.swift
//  MapBookmarksApp
//
//  Created by Anton Komir on 7/15/16.
//  Copyright © 2016 Anton Komir. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import CoreData

class BookmarkDetails:UIViewController, UITableViewDelegate,UITableViewDataSource {
    internal var bookmark: MapBookmark? = nil
    internal var location:CLLocation? = nil
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var searchNearByPlaces: UIButton!
    
    var shouldReloadData = false
    var shouldCentered = false
    var shouldGoTo = false
    
    var lastLocation:CLLocation?
    var venues = (try! Realm()).objects(Venue)
    
    var placeCellIdentifier = "PlaceIdentifier"
    @IBOutlet weak var nearByPlacesTalbeView: UITableView!
    
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        return managedContext
    }()
    var fetchedResultsController: NSFetchedResultsController!
    var entity: NSEntityDescription? = nil
    var deletedBookmark = false
    var savedBookmark:NSManagedObject? = nil
    
    var deleteAll = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (bookmark != nil) {
            titleField.text = bookmark!.title
        }
        navigationItem.rightBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(self.deleteBookmark))
        let newBackButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(self.checkSavePopup))
        self.navigationItem.leftBarButtonItem = newBackButton;
        
        // unnamed bookmark
        if (bookmark?.title == "" || bookmark?.title == nil) {
            prepareNearbyPlaces ()
        }
        
        nearByPlacesTalbeView.dataSource = self
        nearByPlacesTalbeView.delegate = self
        
        self.ForsqearePrepare()
        
        self.navigationBarNotTransparent()
        
        entity = NSEntityDescription.entityForName(MapBookmark.entityClass, inManagedObjectContext:context)
    }
    
    func navigationBarNotTransparent () {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = false
    }
    
    func ForsqearePrepare () {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BookmarkDetails.reloadTableNearbyPlaces), name: API.notifications.venuesUpdated, object: nil)
        let realm = try! Realm()
        realm.beginWrite()
        realm.deleteAll()
        venues = realm.objects(Venue)
        do {
            try realm.commitWrite()
            print("Committing write...")
        }
        catch (let e)
        {
            print("Y U NO REALM ? \(e)")
        }
    }
    
    func reloadTableNearbyPlaces () {
        nearByPlacesTalbeView.reloadData()
    }
    
    func prepareNearbyPlaces () {
        searchNearByPlaces.hidden = true
        if (self.location != nil)
        {
            let locationFS: CLLocation = self.location!
            refreshVenues(locationFS, getDataFromFoursquare: true)
        }else if (bookmark != nil) {
            let location: CLLocation = CLLocation.init(latitude: CLLocationDegrees(bookmark!.latitude!), longitude: CLLocationDegrees(bookmark!.longitude!))
            refreshVenues(location, getDataFromFoursquare: true)
        }
    }
    
    func refreshVenues(location: CLLocation?, getDataFromFoursquare:Bool = false)
    {
        if location != nil
        {
            lastLocation = location
        }
        
        if let location = lastLocation
        {
            if getDataFromFoursquare == true
            {
                FoursquareAPIConnector.sharedInstance.getNearbyPlacesWithLocation(location)
            }
            
            let realm = try! Realm()
            
            venues = realm.objects(Venue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func deleteBookmark () {
        let refreshAlert = UIAlertController(title: "Delete", message: "A map bookmark will be lost.", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
            self.shouldReloadData = true
            self.setState()
            self.deleteBookmarkFromCoreData()
            self.navigationController?.popViewControllerAnimated(true);
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            
        }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
    func setState () {
        let parentViewController = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 1]
        var mapViewController: MapViewController
        if parentViewController is MapViewController {
            mapViewController = parentViewController as! MapViewController
        }
        else {
            mapViewController = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as! MapViewController
        }
        
        mapViewController.shouldReloadData = self.shouldReloadData
        mapViewController.shouldCentered = self.shouldCentered
        mapViewController.shouldGoTo = self.shouldGoTo
    }
    
    @IBAction func shouldBeCentered(sender: AnyObject) {
        self.shouldCentered = true
        self.setState()
        self.checkAndSave()
        popToMap()
    }
    @IBAction func shouldGoToAction(sender: AnyObject) {
        self.shouldGoTo = true
        self.setState()
        self.checkAndSave()
        popToMap()
    }
    
    func popToMap () {
        let parentViewController = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 1]
        var mapViewController: MapViewController
        if navigationController?.parentViewController is MapViewController {
            mapViewController = parentViewController as! MapViewController
        }
        else {
            mapViewController = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as! MapViewController
        }
        
        self.navigationController?.popToViewController(mapViewController, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
//        if (self.deletedBookmark == false) {
//            saveBookmark()
//        }
        self.shouldReloadData = true
        self.setState()
    }
    
    func checkSavePopup () {
        checkAndSave ()
        self.navigationController?.popViewControllerAnimated(true);
    }
    
    func checkAndSave () {
        if (self.titleField.text == "") {
            let refreshAlert = UIAlertController(title: "Name", message: "Can't be bookmark without name.", preferredStyle: UIAlertControllerStyle.Alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action: UIAlertAction!) in
                self.shouldReloadData = true
                self.setState()
                self.deleteBookmarkFromCoreData()
                self.navigationController?.popViewControllerAnimated(true);
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                
            }))
            
            presentViewController(refreshAlert, animated: true, completion: nil)
        } else {
            self.shouldReloadData = true
            self.setState()
            saveBookmark()
        }
    }
    
    func saveBookmark () {
        let entity =  NSEntityDescription.entityForName(MapBookmark.entityClass, inManagedObjectContext:context)
        
        let mapBookmark = NSManagedObject(entity: entity!,
                                          insertIntoManagedObjectContext: context)
        
        mapBookmark.setValue(self.titleField.text, forKey: MapBookmark.titleLabel)
        if (location != nil) {
            mapBookmark.setValue(Double(location!.coordinate.longitude), forKey: MapBookmark.longitudeTitle)
            mapBookmark.setValue(Double(location!.coordinate.latitude), forKey: MapBookmark.latitudeTitle)
        } else {
            mapBookmark.setValue(Double(bookmark!.longitude!), forKey: MapBookmark.longitudeTitle)
            mapBookmark.setValue(Double(bookmark!.latitude!), forKey: MapBookmark.latitudeTitle)
        }
        mapBookmark.setValue(NSDate(), forKey: MapBookmark.dataTitle)
        
        do {
            try context.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        let parentViewController = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 1]
        var mapViewController: MapViewController
        if navigationController?.parentViewController is MapViewController {
            mapViewController = parentViewController as! MapViewController
        }
        else {
            mapViewController = navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as! MapViewController
        }
        mapViewController.selectedBookmark = mapBookmark as! MapBookmark;
    }
    
    func deleteBookmarkFromCoreData () {
        if (deleteAll) {
//            let fetchPredicateFirst = NSPredicate(format: "%@ == %f", MapBookmark.latitudeTitle,
//                                                  self.bookmark!.latitude!)
//            let fetchPredicateSecond = NSPredicate(format: "%@ == %f", MapBookmark.longitudeTitle,
//                                                   self.bookmark!.longitude!)
//            
            let fetchBookmark = NSFetchRequest(entityName: MapBookmark.entityClass)
//            let andPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [fetchPredicateFirst, fetchPredicateSecond])
            //fetchBookmark.predicate = fetchPredicateFirst
            fetchBookmark.returnsObjectsAsFaults   = false
            
            var fetchedBookmarks: [NSManagedObject]? = nil
            
            do {
                fetchedBookmarks = try context.executeFetchRequest(fetchBookmark) as? [NSManagedObject]
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            
            for fetchedBookmark in fetchedBookmarks! {
                context.deleteObject(fetchedBookmark)
                
                do {
                    try context.save()
                } catch let error as NSError  {
                    print("Could not save \(error), \(error.userInfo)")
                }
            }

        }
        if (bookmark != nil) {
            context.deleteObject((self.bookmark!) as NSManagedObject)
            do {
                try context.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        self.deletedBookmark = true
    }
    
    // MARK: about nearby places
    
    
    @IBAction func loadNearbyPlaces(sender: AnyObject) {
        prepareNearbyPlaces ()
    }
    
    // MARK:  UITextFieldDelegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(placeCellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = venues[indexPath.row].name
        
        return cell
    }
    
    // MARK:  UITableViewDelegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        nearByPlacesTalbeView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let row = indexPath.row
        print(venues[row].name)
        self.replaceBookmark(venues[row].name, longitude: Double(venues[row].longitude), latitude: Double(venues[row].latitude))
    }
    
    func replaceBookmark (title:String, longitude: Double, latitude: Double) {
        self.titleField.text = title
        
        location = CLLocation.init(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
    }
}