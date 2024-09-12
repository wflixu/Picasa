//
//  ContentView.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/1.
//

import AppKit
import SDWebImageSwiftUI
import SwiftUI

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

    // ScrollView的偏移状态，用来实现拖动查看图片的不同部分
    @State private var scrollViewOffset: CGSize = .zero
    @State private var lastDragPosition: CGSize = .zero

    @State private var scrollViewProxy: ScrollViewProxy? = nil


    var body: some View {
        GeometryReader { geometry in

            ZStack(alignment: .leading) {
                ScrollViewReader { scroller in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(appState.imageFiles.enumerated()), id: \.offset) { index, imageURL in
                                ImageThumbnailView(imageURL: imageURL, isSelected: appState.selectedImageIndex == index).id(index)
                                    .onTapGesture {
                                        loadImage(at: index)
                                    }
                            }
                        }

                        .padding()
                    }
                    .scrollIndicators(.never)
                    .frame(width: 128, height: geometry.size.height) // 导航条宽度固定为160
                    .background(Color.gray.opacity(0.6)) // 半透明背景
                    .shadow(radius: 5)
                    .onAppear {
                        print("scrollViewProxy ....... init")
                        scrollViewProxy = scroller
                    }

                    // 确保浮动在主视图上方
                }
                .position(x: 64, y: geometry.size.height / 2)
                .zIndex(20)

                HStack {
                    if let currentImage = currentImage {
                        ScrollView([.horizontal, .vertical], showsIndicators: false) {
                            // 使用 Image 组件加载图片，并设置其大小大于 ScrollView 的视图大小
                            Image(nsImage: currentImage)
                                .resizable()
                                .frame(width: currentImage.size.width, height: currentImage.size.height)
                                .scaleEffect(scale, anchor: .center)
                                .offset(x: scrollViewOffset.width, y: scrollViewOffset.height) // 通过偏移来控制图片的位置
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            // 计算拖动的偏移量，并更新状态
                                            let newOffset = CGSize(
                                                width: lastDragPosition.width + value.translation.width,
                                                height: lastDragPosition.height + value.translation.height
                                            )

                                            // 将新的偏移值设置到视图中
                                            scrollViewOffset = newOffset
                                        }
                                        .onEnded { _ in
                                            // 保存拖动结束时的位置
                                            lastDragPosition = scrollViewOffset
                                        }
                                )
                                .onTapGesture {
                                    appState.appDelegate?.startShowWindowTitlebar()
                                   
                                }
                        }
                        .clipped() // 保证视图的边缘不显示超出内容

                    } else {
                        HStack {
                            Button("Select Image File") {
                                showFileSelector = true
                            }
                            .fileImporter(isPresented: $showFileSelector, allowedContentTypes: [.png, .jpeg, .gif, .webP]) { result in
                                handleFileSelect(result)
                            }
                        }
                    }
                }.frame(width: geometry.size.width, height: geometry.size.height)
                    .zIndex(0)
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
            if !gotAccess { 
                logger.warning("not got access")
                return }
            // access the directory URL
        
            if let appDelegate = appState.appDelegate {
                appDelegate.loadImages(from: fileUrl)
                loadImage(at: appState.selectedImageIndex)
            } else {
                logger.warning("not appDelegate")
            }

        // release access
//            fileUrl.stopAccessingSecurityScopedResource()
        case .failure(let error):
            // handle error
                logger.error("error: \(error)")
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
        print("loadImage ........")
        guard appState.imageFiles.indices.contains(index) else { return }
        // 获取图片 URL
        let url = appState.imageFiles[index]

        // 更新 AppState 中的 currentImageURL 和 selectedImageIndex
        appState.currentImageURL = url
        appState.selectedImageIndex = index
        scrollViewProxy?.scrollTo(index)

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
