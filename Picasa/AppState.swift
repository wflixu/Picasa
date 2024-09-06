//
//  AppState.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/5.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppLog(category: "AppState")
    private var logger

    @Published var currentImageURL: URL?
    @Published var imageFiles: [URL] = []
    @Published var selectedImageIndex: Int = 0

    /// The app's delegate.
    private(set) weak var appDelegate: AppDelegate?

    /// The window that contains the settings interface.
    private(set) weak var settingsWindow: NSWindow?

    /// Assigns the app delegate to the app state.
    func assignAppDelegate(_ appDelegate: AppDelegate) {
        guard self.appDelegate == nil else {
            logger.warning("Multiple attempts made to assign app delegate")
            return
        }
        self.appDelegate = appDelegate
    }

    /// Assigns the settings window to the app state.
    func assignSettingsWindow(_ settingsWindow: NSWindow) {
        guard self.settingsWindow == nil else {
            logger.warning("Multiple attempts made to assign settings window")
            return
        }
        self.settingsWindow = settingsWindow
    }

    /// Activates the app and sets its activation policy to the given value.
    func activate(withPolicy policy: NSApplication.ActivationPolicy) {
        // store whether the app has previously activated inside an internal
        // context to keep it isolated
        enum Context {
            static let hasActivated = ObjectAssociation<Bool>()
        }

        func activate() {
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                NSRunningApplication.current.activate(from: frontApp)
            } else {
                NSApp.activate()
            }
            NSApp.setActivationPolicy(policy)
        }

        if Context.hasActivated[self] == true {
            activate()
        } else {
            Context.hasActivated[self] = true
            logger.debug("First time activating app, so going through Dock")
            // hack to make sure the app properly activates for the first time
            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                activate()
            }
        }
    }
}
