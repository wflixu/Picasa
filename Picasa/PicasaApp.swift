//
//  PicasaApp.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/1.
//

import AppKit
import SwiftUI

@main
struct PicasaApp: App {
    @AppLog(category: "PicasaApp")
    private var logger

    // 设置 App Delegate 以响应 open file 请求
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var appState = AppState()

    init() {
        appDelegate.assignAppState(appState)

//        // 获取命令行参数
//        let arguments = CommandLine.arguments
//        logger.info("Launch arguments: \(arguments[1])")
//
//        if  let fileURL = URL(string: arguments[1]) {
//            appDelegate.loadImages(from: fileURL)
//        } else {
//            logger.info("not get fileURL from arguments ")
//        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
        }.environmentObject(appState)
    }
}

// AppDelegate 负责处理文件打开请求
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    @AppLog(category: "AppState")
    private var logger

    private var appState: AppState?

    func applicationWillFinishLaunching(_ notification: Notification) {
        logger.info("---- app will finish launch")
        guard let appState else {
            logger.warning("Missing app state in applicationWillFinishLaunching")
            return
        }

        // assign the delegate to the shared app state
        appState.assignAppDelegate(self)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        logger.info("application open urls")
        guard let currentImageURL = urls.first else {
            return
        }
        print("Received file URL: \(currentImageURL)")
        loadImages(from: currentImageURL)
    }
    

    /// Opens the settings window and activates the app.
    @objc func openSettingsWindow() {
        guard
            let appState,
            let settingsWindow = appState.settingsWindow
        else {
            logger.warning("Failed to open settings window")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            appState.activate(withPolicy: .regular)
            settingsWindow.center()
            settingsWindow.makeKeyAndOrderFront(self)
        }
    }

    /// Assigns the app state to the delegate.
    func assignAppState(_ appState: AppState) {
        guard self.appState == nil else {
            logger.warning("Multiple attempts made to assign app state")
            return
        }
        self.appState = appState
    }

    func loadImages(from url: URL) {
        print("loadImages ....")
        let directory = url.deletingLastPathComponent()
        guard let appState else { return}
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            appState.imageFiles = fileURLs.filter { ["png", "jpg", "jpeg", "gif", "webp"].contains($0.pathExtension.lowercased()) }
            appState.selectedImageIndex = appState.imageFiles.firstIndex(where: { $0.path == url.path }) ?? 0
            appState.currentImageURL = url;
            print("loadimagesfiles ... \(appState.selectedImageIndex)")
        } catch {
            print("Error reading contents of directory: \(error.localizedDescription)")
        }
    }
}
