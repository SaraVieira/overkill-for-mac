//
//  OverkillController.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

class OverkillController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var pauseButton: NSMenuItem!

    var preferencesWindow: PreferencesWindow!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    var blackListedProcessNames: [String] = []
    var overkillIsPaused = false
    

    override func awakeFromNib() {
        statusItem.title = "Overkill"
        statusItem.menu = statusMenu
        
        self.blackListedProcessNames = ["com.apple.iTunes", "com.apple.Photos"] // TODO: move to preferences
        startListening()
    }

    @IBAction func didClickPreferences(_ sender: Any) {
        preferencesWindow = PreferencesWindow()
        preferencesWindow.showWindow(nil)
    }

    @IBAction func didClickExit(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }
    
    func startListening() {
        let n = NSWorkspace.shared().notificationCenter
        n.addObserver(self, selector: #selector(self.appWillLaunch(note:)),
                      name: .NSWorkspaceWillLaunchApplication,
                      object: nil)
        
        self.killRunningApps()
    }
    
    func stopListening() {
        let n = NSWorkspace.shared().notificationCenter
        n.removeObserver(self, name: .NSWorkspaceWillLaunchApplication, object: nil)
    }
    
    func killRunningApps() {
        let runningApplications = NSWorkspace.shared().runningApplications
        for currentApplication in runningApplications.enumerated() {
            let runningApplication = runningApplications[currentApplication.offset]
            
            if (runningApplication.activationPolicy == .regular) { // normal macOS application
                if (self.blackListedProcessNames.contains(runningApplication.bundleIdentifier!)) {
                    self.killProcess(Int(runningApplication.processIdentifier))
                }
            }
        }
    }
    
    func appWillLaunch(note:Notification) {
        if let processBundleIdentifier:String = note.userInfo?["NSApplicationBundleIdentifier"] as? String { // the bundle identifier
            if let processId = note.userInfo?["NSApplicationProcessIdentifier"] as? Int { // the pid
                if (self.blackListedProcessNames.contains(processBundleIdentifier)) {
                    self.killProcess(processId)
                }
            }
        }
    }

    func killProcess(_ processId:Int) {
        if let process = NSRunningApplication.init(processIdentifier: pid_t(processId)) {
            print("Killing \(processId): \(String(describing: process.localizedName))")
            process.forceTerminate()
        }
    }
    
    @IBAction func didClickPause(_ sender: Any) {
        self.overkillIsPaused = !self.overkillIsPaused
        
        if (self.overkillIsPaused) {
            self.stopListening()
            self.pauseButton.title = "Resume Overkill"
        } else {
            self.startListening()
            self.pauseButton.title = "Pause Overkill"
        }
    }
}
