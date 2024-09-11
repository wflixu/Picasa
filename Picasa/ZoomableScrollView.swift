//
//  ImageViewer.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/7.
//

import AppKit
import SwiftUI

struct ZoomableScrollView<Content: View>: NSViewRepresentable {
    var content: Content
    var imageSize: CGSize
    var scale: CGSize
    var winSize: CGSize

    init(imageSize: CGSize, scale: CGSize, winSize: CGSize, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.scale = scale
        self.imageSize = imageSize
        self.winSize = winSize
    }

    class Coordinator: NSObject {
        var parent: ZoomableScrollView
        var localEventMonitor: Any?
        var imageView: NSHostingView<Content>?
        var scrollView: NSScrollView?

        init(parent: ZoomableScrollView) {
            self.parent = parent
        }

        // 移除事件监听
        func removeScrollWheelMonitor() {
            if let monitor = localEventMonitor {
                NSEvent.removeMonitor(monitor)
                localEventMonitor = nil
            }
        }

        // 滚动到指定位置
        func scrollTo(x: CGFloat, y: CGFloat) {
            if let scrollView = scrollView {
                let contentView = scrollView.contentView

                let newOrigin = NSPoint(x: x, y: y)
                contentView.setBoundsOrigin(newOrigin)
            }
        }

        @objc func handlePan(_ gesture: NSPanGestureRecognizer) {
            print("handlePan ....")
            guard let imageView = imageView else { return }

            guard let scrollView = scrollView else { return }
            // Get the translation (pan movement)
            let translation = gesture.translation(in: imageView)
            let last = scrollView.contentView.bounds.origin
            
            print("33333 handlePan ....")
            scrollView.contentView.setBoundsOrigin(NSPoint(x: last.x - translation.x, y: last.y - translation.y))

            // Reset the translation to avoid cumulative translation over time
            gesture.setTranslation(.zero, in: imageView)
        }

        deinit {
            removeScrollWheelMonitor()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .legacy
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .gray
        scrollView.autohidesScrollers = false
        scrollView.scroll(CGPoint(x: 800, y: 800))

        // 设置内容视图
        let documentView = NSHostingView(rootView: content)
        documentView.frame = NSRect(origin: .zero, size: getDocFrame(image: imageSize, win: winSize, scale: scale))
        scrollView.documentView = documentView

        // Enable drag-to-pan by adding a pan gesture recognizer
        let panGestureRecognizer = NSPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        documentView.addGestureRecognizer(panGestureRecognizer)

        // Store the reference to imageView in the coordinator
        context.coordinator.imageView = documentView
        context.coordinator.scrollView = scrollView

        let contentView = scrollView.contentView

        let newOrigin = NSPoint(x: imageSize.width - contentView.bounds.size.width, y: (imageSize.height - contentView.bounds.size.height) / 2)
        contentView.setBoundsOrigin(newOrigin)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let documentView = nsView.documentView as? NSHostingView<Content> {
            print("start updateNSView")
            documentView.rootView = content
            documentView.frame = NSRect(origin: .zero, size: getDocFrame(image: imageSize, win: winSize, scale: scale))
        }
    }

    func getDocFrame(image: CGSize, win: CGSize, scale: CGSize) -> CGSize {
        let width = max(image.width * scale.width, win.width)
        let height = max(image.height * scale.height, win.height)
        return CGSize(width: width, height: height)
    }

    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.removeScrollWheelMonitor()
    }
}
