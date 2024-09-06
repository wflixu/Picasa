//
//  ContentView.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/1.
//

import SDWebImageSwiftUI
import SwiftUI

struct ContentView: View {
    @AppLog(category: "ContentView")
    private var logger

    @EnvironmentObject var appState: AppState

    @State private var currentImage: NSImage?
    @State private var scale: CGFloat = 0.5

    @State private var isNavBarVisible: Bool = true
    @State private var isCommandPressed: Bool = false

    @State private var window: NSWindow?

    @State var scrollOffset: CGPoint = .zero

    @State var scaleAnchor: UnitPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            
        }
        ZStack(alignment: .topLeading) {
            HStack {
                Text("x: \(scrollOffset.x)")

                Text("y: \(scrollOffset.y)")
            }
            .foregroundStyle(.red)
            .zIndex(100)
            if let currentImage = currentImage {
                ZoomableImageView(image: currentImage)
                    // 视图铺满整个窗口
            } else {
                Text("No Image Selected")
            }

//            GeometryReader { geometry in
//                ScrollView([.horizontal, .vertical]) {
//                    VStack {
//                        Text("suze: \(geometry.size)")
//                            .font(.title)
//                            .foregroundStyle(.red)
//                    }
//
//                    if let currentImage = currentImage {

//                        Image(nsImage: currentImage)
//                            .resizable()
//
//                            .scaleEffect(scale)
//                            .border(Color.red , width: 4)
//                            .gesture(
//                                MagnificationGesture()
//                                    .onChanged { value in
//                                        scale = value
//                                    }
//                            )
//                            .gesture(
//                                DragGesture(minimumDistance: 5)
//                                    .onChanged { value in
//
//                                        scrollOffset.x += value.translation.height
//                                        scrollOffset.y += value.translation.width
//                                    }
//                            )
//                            .onAppear {
//                                // 监听 Command 键的按下事件
//                                NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
//                                    if event.modifierFlags.contains(.command) {
//                                        isCommandPressed = true
//                                    } else {
//                                        isCommandPressed = false
//                                    }
//                                    return event
//                                }
//                                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
//                                    if isCommandPressed { // 只有按下 Command 键时才缩放
//                                        let delta = event.scrollingDeltaY
//
//                                        scale += delta / 500 // 根据滚轮的滚动量进行缩放
//                                        return nil // 防止滚动事件传递给其他组件
//                                    }
//                                    return event
//                                }
//                            }
//                    } else {
//                        Text("No Image Selected")
//                    }
//                }
//                .frame(width: geometry.size.width, height: geometry.size.height)
//                .defaultScrollAnchor(.center)
            ////                .scrollIndicators(.never)
            ////                .offset(x: scrollOffset.x, y: scrollOffset.y)
//                .onChange(of: appState.currentImageURL) { _, newURL in
//                    print("watch image changeed \(geometry.size)")
//                    if let url = newURL {
//                        currentImage = NSImage(contentsOf: url)
//                    } else {
//                        loadImage(at: appState.selectedImageIndex)
//                    }
//                }
//            }
            // 左侧浮动导航条
            if isNavBarVisible {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 5) {
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
                }
                .frame(width: 160) // 导航条宽度固定为160
                .background(Color.gray.opacity(0.4)) // 半透明背景
                .shadow(radius: 5)
                .ignoresSafeArea(.container)
                .zIndex(20) // 确保浮动在主视图上方
            }
        }
        .frame(width:800, height: 600)
//        .edgesIgnoringSafeArea(.all)
        .onAppear(perform: appearHandler)
    }

    func appearHandler() {
        setupKeyEvents()
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

        if let window = getWindow() {
            self.window = window
            hideTitleBar() // 初始隐藏
        } else {
            logger.info("can't get window")
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

    // 获取当前窗口
    private func getWindow() -> NSWindow? {
        return NSApplication.shared.windows.first { $0.isVisible }
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

struct ZoomableImageView: NSViewRepresentable {
    var image: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.frame = CGRect(origin: .zero, size: CGSize(width: 800, height: 600))

        let scrollView = NSScrollView()
   
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.documentView = imageView
        scrollView.frame = CGRect(origin:.zero, size: CGSize(width: 800, height: 600))
        let magnificationGestureRecognizer = NSMagnificationGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleMagnification(_:)))
        imageView.addGestureRecognizer(magnificationGestureRecognizer)

        let panGestureRecognizer = NSPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        imageView.addGestureRecognizer(panGestureRecognizer)

        scrollView.addSubview(imageView)

        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = image
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ZoomableImageView
        var currentScale: CGFloat = 1.0
        var isCommandPressed: Bool = false

        init(_ parent: ZoomableImageView) {
            self.parent = parent
            super.init()
            // 监听键盘事件，检测 Command 键是否按下
            NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { event in
                if event.type == .flagsChanged {
                    self.isCommandPressed = event.modifierFlags.contains(.command)
                }
                return event
            }
        }

        @objc func handleMagnification(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
            let magnification = gestureRecognizer.magnification + 1.0
            currentScale *= magnification

            gestureRecognizer.view?.scaleUnitSquare(to: NSSize(width: magnification, height: magnification))
            gestureRecognizer.magnification = 0 // Reset magnification after applying
        }

        @objc func handlePan(_ gestureRecognizer: NSPanGestureRecognizer) {
            guard let view = gestureRecognizer.view else { return }
            let translation = gestureRecognizer.translation(in: view)
            gestureRecognizer.view?.setFrameOrigin(NSPoint(x: view.frame.origin.x + translation.x, y: view.frame.origin.y + translation.y))
            gestureRecognizer.setTranslation(.zero, in: view)
        }
    }
}

#Preview {
    ContentView()
}
