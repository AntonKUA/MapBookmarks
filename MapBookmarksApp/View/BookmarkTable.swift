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

class BookmarkTable: UITableViewController, NSFetchedResultsControllerDelegate {
    let textCellIdentifier = "TextCell"
    var mapBookmarks = [MapBookmark]()
    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        return managedContext
    }()
    var fetchedResultsController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let nib = UINib(nibName: textCellIdentifier, bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier:textCellIdentifier)
        
        self.loadData()
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
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapBookmarks.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as! BookmarkTableViewCell
        
        cell.label2.text = mapBookmarks[indexPath.row].title
        
        return cell
    }
    
    // MARK:  UITableViewDelegate Methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let row = indexPath.row
        print(mapBookmarks[row].title)
    }
}