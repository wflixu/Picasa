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

    @Environment(\.openWindow) private var openWindow

    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    // 设置 App Delegate 以响应 open file 请求
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var appState = AppState()

    init() {
        logger.info("app init .....")
        appDelegate.assignAppState(appState)
    }

    var body: some Scene {
        WindowGroup("Picasa", id: "main") {
            ContentView().onAppear {
                if appState.showCurDirImg && appState.dirs.isEmpty {
                    openWindow(id: Constants.settingsWindowID)
                }
            }
        }
        .defaultPosition(.center)
        .defaultSize(width: 1280, height: 720)
        .environmentObject(appState)

        SettingsWindow(appState: appState, onAppear: {})
       
        MenuBarExtra(
            "Picasa", image:"menubarIcon", isInserted: $showMenuBarExtra
        ) {
            MenuBarView()
        }.environmentObject(appState)
    }
}

// AppDelegate 负责处理文件打开请求
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    @AppLog(category: "AppState")
    private var logger

    private var appState: AppState?

    private var isTitleBarVisible = false
    private var hideTitleBarTimer: Timer?

    func applicationWillFinishLaunching(_ notification: Notification) {
        logger.info("---- app will finish launch")
        guard let appState else {
            logger.warning("Missing app state in applicationWillFinishLaunching")
            return
        }

        // assign the delegate to the shared app state
        appState.assignAppDelegate(self)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("applicationDidFinishLaunching  .......")
        for window in NSApplication.shared.windows {
            // 检查窗口的标题是否匹配
            if window.title == "Picasa" {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true

                // 移除标题栏的 style mask
                window.styleMask.remove(.titled)
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        logger.info("application open urls")
        guard let currentImageURL = urls.first else {
            return
        }
        print("Received file URL: \(currentImageURL)")
        loadImages(from: currentImageURL)
    }

    @MainActor
    func startShowWindowTitlebar() {
        // 取消之前的定时器，避免重复调用
        hideTitleBarTimer?.invalidate()

        isTitleBarVisible = true
        updateWindowTitleBarVisibility()
        // 20秒后隐藏标题栏
        hideTitleBarTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.isTitleBarVisible = false
            self?.updateWindowTitleBarVisibility()
        }
    }

    @MainActor
    func updateWindowTitleBarVisibility() {
        for window in NSApplication.shared.windows {
            // 检查窗口的标题是否匹配
            if window.title == "Picasa" {
                if isTitleBarVisible {
                    window.titleVisibility = .visible
                    window.styleMask.insert(.titled)
                } else {
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    // 移除标题栏的 style mask
                    window.styleMask.remove(.titled)
                }

                break
            }
        }
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
        logger.warning("loadImages ....")
        guard let appState else {
            logger.warning("not have appState")
            return
        }
        if appState.showCurDirImg == true {
            let directory = url.deletingLastPathComponent()

            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                appState.imageFiles = fileURLs.filter { ["png", "jpg", "jpeg", "gif", "webp"].contains($0.pathExtension.lowercased()) }
                appState.selectedImageIndex = appState.imageFiles.firstIndex(where: { item in
                    print("item \(item.path) --- url: \(url.path)")
                    return item.path == url.path
                }) ?? 0
                appState.currentImageURL = url
                logger.warning("loadimagesfiles ... \(appState.selectedImageIndex)")
            } catch {
                logger.error("Error reading contents of directory: \(error.localizedDescription)")
            }
        } else {
            appState.imageFiles.append(url)
            appState.selectedImageIndex = 0
            appState.currentImageURL = url
        }
    }
}
