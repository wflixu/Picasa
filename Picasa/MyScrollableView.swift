//
//  MyScrollableView.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/7.
//

import AppKit
import SwiftUI

// 创建一个 NSScrollView 的 SwiftUI 封装
struct MyScrollableView<Content: View>: NSViewRepresentable {
    var content: Content

    var scale: CGFloat // 添加 scale 参数

    init(scale: CGFloat = 1.0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.scale = scale // 初始化 scale
    }

    // 创建并配置 NSScrollView
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .lineBorder

        // 设置 documentView，并进行缩放
        let documentView = NSHostingView(rootView: content)
        documentView.setFrameSize(NSSize(width: documentView.fittingSize.width * scale,
                                         height: documentView.fittingSize.height * scale))
        documentView.scaleUnitSquare(to: NSSize(width: scale, height: scale)) // 应用缩放

        scrollView.documentView = documentView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let documentView = nsView.documentView as? NSHostingView<Content> {
            // 更新内容和缩放
            documentView.rootView = content
            documentView.setFrameSize(NSSize(width: documentView.fittingSize.width * scale,
                                             height: documentView.fittingSize.height * scale))
            documentView.scaleUnitSquare(to: NSSize(width: scale, height: scale)) // 应用缩放
        }
    }
}
