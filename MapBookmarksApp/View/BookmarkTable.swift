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
    var placeCellIdentifier = "Bookmark"
    var mapBookmarks = [MapBookmark]()
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        return managedContext
    }()
    var fetchedResultsController: NSFetchedResultsController!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableHeaderView = nil
        
        navigationBarNotTransparent ()
        
        self.loadData()
    }
    
    func navigationBarNotTransparent () {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = false
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
        
    }
}