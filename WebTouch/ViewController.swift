//
//  ViewController.swift
//  WebTouch
//
//  Created by Gokul Swamy on 1/2/17.
//  Copyright © 2017 Gokul Swamy. All rights reserved.
//

import Cocoa
import Foundation

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTouchBarDelegate {

    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var eventField: NSTextField!
    var key = [NSManagedObject]()
    var managedContext : NSManagedObjectContext?
    var data = [NSManagedObject]()
    var selectedEvent: NSManagedObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MakerKey")
        do {
            key = try managedContext!.fetch(fetchRequest) as! [NSManagedObject]
            if key.count > 0{
                textField.stringValue = key[0].value(forKey: "key") as! String
            }
        } catch {
            print(error)
        }
        tableView.delegate = self
        tableView.dataSource = self
        reloadData()
        selectedEvent = nil
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func update(_ sender: Any) {
        if textField.stringValue.characters.count < 5{
            let alert = NSAlert()
            alert.messageText = "No Maker Channel Key"
            alert.informativeText = "Please paste in a valid Maker Channel Key."
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "Ok")
            alert.runModal()
        }
        else{
            let newKey = textField.stringValue
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MakerKey")
            do {
                key = try managedContext!.fetch(fetchRequest) as! [NSManagedObject]
                if key.count > 0{
                    key[0].setValue(newKey, forKey: "key")
                    do {
                        try managedContext?.save()
                    }catch {
                        print(error)
                    }
                }
                else{
                    let newKey = textField.stringValue
                    let entity = NSEntityDescription.entity(forEntityName: "MakerKey", in: managedContext!)
                    let object = NSManagedObject(entity: entity!, insertInto: managedContext)
                    object.setValue(newKey, forKey: "key")
                    do {
                        try managedContext?.save()
                    } catch {
                        print("error saving")
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func addEvent(_ sender: Any) {
        if eventField.stringValue.characters.count < 1{
            let alert = NSAlert()
            alert.messageText = "No Event Name"
            alert.informativeText = "Please paste in a valid Event Name."
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "Ok")
            alert.runModal()
        }
        else{
            let newEvent = eventField.stringValue
            let entity = NSEntityDescription.entity(forEntityName: "Event", in: managedContext!)
            let object = NSManagedObject(entity: entity!, insertInto: managedContext)
            object.setValue(newEvent, forKey: "name")
            do {
                try managedContext?.save()
            } catch {
                print("error saving")
            }
        }
        reloadData()
        eventField.stringValue = ""
        self.storyboard?.instantiateController(withIdentifier: "window")
    }
    
    @IBAction func removeEvent(_ sender: Any) {
        if let oldEvent = selectedEvent{
            managedContext?.delete(oldEvent)
            do {
                try managedContext?.save()
                reloadData()
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func openHelp(_ sender: Any) {
        let url = URL(string: "http://gok.cool")
        NSWorkspace.shared().open(url!)
        
    }
    
    func reloadData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
        do {
            data = try managedContext!.fetch(fetchRequest) as! [NSManagedObject]
            tableView.reloadData()
        } catch {
            print(error)
        }
        if #available(OSX 10.12.2, *) {
            self.touchBar = self.makeTouchBar()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        let event = data[row]
        if let eventName = event.value(forKey: "name") as? String {
            result.textField?.stringValue = eventName
        } else {
            result.textField?.stringValue = ""
        }
        return result
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let selectedRow = (notification.object as AnyObject).selectedRow {
            if (selectedRow >= 0 ) {
                selectedEvent = data[selectedRow]
            } else {
                selectedEvent = nil
            }
        }
    }
    
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = NSTouchBarCustomizationIdentifier("com.gokulswamy.webtouch")
        if ((NSClassFromString("NSTouchBar")) != nil) {
            NSApplication.shared().isAutomaticCustomizeTouchBarMenuItemEnabled = true
        }
        var ids: [NSTouchBarItemIdentifier] = []
        for event in data{
            ids.append(NSTouchBarItemIdentifier(event.value(forKey: "name") as! String))
        }
        touchBar.defaultItemIdentifiers = ids
        return touchBar
    }
    
    @available(OSX 10.12.2, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        item.view = NSButton(title: identifier.rawValue, target: self, action: #selector(webRequest(sender:)))
        return item
    }
    
    @objc func webRequest(sender: NSButton){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MakerKey")
        do {
            let request = try managedContext!.fetch(fetchRequest) as! [NSManagedObject]
            if request.count > 0{
                let key = request[0].value(forKey: "key") as! String
                let url = "https://maker.ifttt.com/trigger/"+sender.title+"/with/key/"+key
                do{
                    var request = URLRequest(url: URL(string: url)!)
                    request.httpMethod = "POST"
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error != nil {
                            print(error!)
                        } else {
                            print(String(data: data!, encoding: String.Encoding.utf8)!)
                        }
                        }.resume()
                }
            }
            else{
                let alert = NSAlert()
                alert.messageText = "No Maker Channel Key"
                alert.informativeText = "Please paste in a valid Maker Channel Key."
                alert.alertStyle = NSAlertStyle.warning
                alert.addButton(withTitle: "Ok")
                alert.runModal()
            }
        } catch {
            print(error)
        }
    }
}


