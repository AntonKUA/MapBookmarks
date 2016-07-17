//
//  BookmarkTable.swift
//  MapBookmarksApp
//
//  Created by Anton Komir on 7/15/16.
//  Copyright © 2016 Anton Komir. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class BookmarkTable:  UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    let placeCellIdentifier = "Bookmark"
    let detailSegue = "DetailFromTable"
    var mapBookmarks = [MapBookmark]()
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        return managedContext
    }()
    var fetchedResultsController: NSFetchedResultsController!
    var selectedRow:Int? = nil
    var editingMode = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableHeaderView = nil
        
        navigationBarNotTransparent ()
        standartNavigationBarItems ()
        
        self.loadData()
    }
    
    func standartNavigationBarItems () {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(self.editTableMode))
        self.editingMode = false
        self.tableView.editing = false
        self.tableView.reloadData()
    }
    
    func editTableMode () {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(self.standartNavigationBarItems))
        self.editingMode = true
        self.tableView.editing = true
        tableView.reloadData()
    }
    
    func navigationBarNotTransparent () {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = false
    }
    
    override func viewWillAppear(animated: Bool) {
        loadData ()
        tableView.reloadData()
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
        
        mapBookmarks = [MapBookmark]()
        
        let sectionData = fetchedResultsController.fetchedObjects
        
        for mapBookmark in sectionData! {
            mapBookmarks.append(mapBookmark as! MapBookmark)
        }
    }

    // MARK:  UITextFieldDelegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapBookmarks.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(placeCellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = mapBookmarks[indexPath.row].title
        
        return cell
    }
    
    // MARK:  UITableViewDelegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        self.selectedRow = indexPath.row
        performSegueWithIdentifier(detailSegue, sender: view)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            // remove the deleted item from the model
            context.deleteObject(mapBookmarks[indexPath.row] )
            mapBookmarks.removeAtIndex(indexPath.row)
            do {
                try context.save()
            } catch _ {
            }
            
            // remove the deleted item from the `UITableView`
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
//    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if editingStyle == .Delete {
//            print(indexPath.row)
//        }
//    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return  self.editingMode
    }
    
//    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        if (self.tableView.editing) {
//            return UITableViewCellEditingStyle.Delete
//        }
//        return UITableViewCellEditingStyle.None
//    }

    
    // MARK:  Segue preparation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? BookmarkDetails {
            if (self.selectedRow != nil) {
                destination.bookmark = mapBookmarks[self.selectedRow!]
            }
        }
    }
}