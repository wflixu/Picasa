//
//  ContentView.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/1.
//

import SDWebImageSwiftUI
import SwiftUI
import AppKit

struct ContentView: View {
    @AppLog(category: "ContentView")
    private var logger

    @EnvironmentObject var appState: AppState

    @State private var currentImage: NSImage?
    @State private var scale: CGSize = .init(width: 1, height: 1)

    @State private var isNavBarVisible: Bool = true
    @State private var isCommandPressed: Bool = false

    @State private var window: NSWindow?

    @State var scrollOffset: CGPoint = .zero

    @State var scaleAnchor: UnitPoint = .init(x: 0.5, y: 0.5)

    @State private var magnification: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    @State private var mouseLocation: CGPoint = .zero

    @State private var showFileSelector = false

    var body: some View {
        GeometryReader { geometry in

            ZStack(alignment: .leading) {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(appState.imageFiles.enumerated()), id: \.offset) { index, imageURL in
                            ImageThumbnailView(imageURL: imageURL, isSelected: appState.selectedImageIndex == index)
                                .onTapGesture {
                                    loadImage(at: index)
                                }
                        }
                    }

                    .padding()
                }
                .scrollIndicators(.never)
                .frame(width: 128, height: geometry.size.height) // 导航条宽度固定为160
                .background(Color.gray.opacity(0.4)) // 半透明背景
                .shadow(radius: 5)
                .position(x: 64, y: geometry.size.height / 2)
                .zIndex(20) // 确保浮动在主视图上方

                HStack {
                    if let currentImage = currentImage {
                        ZoomableScrollView(imageSize: currentImage.size, scale: scale, winSize: geometry.size) {
                            Image(nsImage: currentImage)
                                .resizable()
                                .frame(width: currentImage.size.width, height: currentImage.size.height)
                                .scaleEffect(scale, anchor: .center)
                        }

                    } else {
                        HStack {
                            Button("Select Image File") {
                                showFileSelector = true
                            }
                            .fileImporter(isPresented: $showFileSelector, allowedContentTypes: [.png, .jpeg]) { result in
                                handleFileSelect(result)
                            }
                        }
                    }
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear(perform: appearHandler)
        }
    }

    func handleFileSelect(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let fileUrl):
            // gain access to the directory
            let gotAccess = fileUrl.startAccessingSecurityScopedResource()
            if !gotAccess { return }
            // access the directory URL
            print("select file \(fileUrl)")
                if let appDelegate = appState.appDelegate  {
                appDelegate.loadImages(from: fileUrl)
               
            }
           
            // release access
//            fileUrl.stopAccessingSecurityScopedResource()
        case .failure(let error):
            // handle error
            print(error)
        }
    }

    // 将全局坐标转换为局部坐标
    func convertGlobalToLocal(_ globalPoint: NSPoint, in geometry: GeometryProxy) -> CGPoint {
        let windowPoint = CGPoint(x: globalPoint.x, y: NSScreen.main?.frame.height ?? 0 - globalPoint.y) // 修正 Y 方向
        let localPoint = geometry.frame(in: .global).origin
        return CGPoint(x: windowPoint.x - localPoint.x, y: windowPoint.y - localPoint.y)
    }

    func appearHandler() {
        setupKeyEvents()
        loadImage(at: appState.selectedImageIndex)
    }

    private func loadImage(at index: Int) {
        guard appState.imageFiles.indices.contains(index) else { return }
        // 获取图片 URL
        let url = appState.imageFiles[index]

        // 更新 AppState 中的 currentImageURL 和 selectedImageIndex
        appState.currentImageURL = url
        appState.selectedImageIndex = index

        // 尝试加载图像
        if let image = NSImage(contentsOf: url) {
            currentImage = image
        }
    }

    private func setupKeyEvents() {
        print("appear \(appState.selectedImageIndex)")

        // 监听 Command 键的按下事件
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            if event.modifierFlags.contains(.command) {
                isCommandPressed = true
            } else {
                isCommandPressed = false
            }
            return event
        }
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if isCommandPressed { // 只有按下 Command 键时才缩放
                let delta = event.scrollingDeltaY

                scale.width += delta / 500
                scale.height += delta / 500 // 根据滚轮的滚动量进行缩放
                return nil // 防止滚动事件传递给其他组件
            }
            return event
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 124, 125: // Right Arrow
                showNextImage()
                return nil
            case 123, 126: // Left Arrow
                showPreviousImage()
                return nil
            default:
                return event
            }
        }
    }

    // 显示标题栏和按钮
    private func showTitleBar() {
        if let window = window {
            withAnimation {
                window.titleVisibility = .visible
                window.standardWindowButton(.closeButton)?.isHidden = false
                window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                window.standardWindowButton(.zoomButton)?.isHidden = false
            }
        }
        // 启动10秒定时器后隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            hideTitleBar()
        }
    }

    // 隐藏标题栏和按钮
    private func hideTitleBar() {
        if let window = window {
            withAnimation {
                window.titleVisibility = .hidden
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
            }
        }
    }

    private func showNextImage() {
        if appState.selectedImageIndex < appState.imageFiles.count - 1 {
            loadImage(at: appState.selectedImageIndex + 1)
        }
    }

    private func showPreviousImage() {
        if appState.selectedImageIndex > 0 {
            loadImage(at: appState.selectedImageIndex - 1)
        }
    }
}

#Preview {
    ContentView()
}
