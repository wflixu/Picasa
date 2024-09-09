//
//  ZoomableImageView.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/7.
//

import SwiftUI

struct ZoomableImageView: NSViewRepresentable {
    var image: NSImage
    var scale: CGFloat = 1.0
    var winSize: CGSize = CGSize(width: 1600, height: 1600)

    func makeNSView(context: Context) -> NSScrollView {
        print("makeNSView ......")
        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.isEditable = false
        imageView.wantsLayer = true
        imageView.layer?.borderWidth = 6
        imageView.layer?.borderColor = NSColor.darkGray.cgColor
        imageView.layer?.cornerRadius = 5
        
        
        
        imageView.frame = CGRect(origin: .zero, size: image.size)

        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        scrollView.borderType = .noBorder
        scrollView.documentCursor = .pointingHand
        scrollView.backgroundColor = .lightGray
        scrollView.drawsBackground = true
      
        scrollView.documentView = imageView
        

        // Enable drag-to-pan by adding a pan gesture recognizer
        let panGestureRecognizer = NSPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        imageView.addGestureRecognizer(panGestureRecognizer)

        // Store the reference to imageView in the coordinator
        context.coordinator.imageView = imageView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let imageView = nsView.documentView as? NSImageView {
            print("asdffas ......")
            imageView.image = image
        }

        print("updateNSView ......")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ZoomableImageView
        var currentScale: CGFloat = 1.0
        var isCommandPressed: Bool = false
        var imageView: NSImageView?

        init(_ parent: ZoomableImageView) {
            self.parent = parent
            super.init()
        }

        @objc func handlePan(_ gesture: NSPanGestureRecognizer) {
            guard let imageView = imageView else { return }
            
            
            // Get the translation (pan movement)
            let translation = gesture.translation(in: imageView)

            // Update the origin of the image view's frame to simulate dragging
            imageView.frame.origin.x += translation.x
            imageView.frame.origin.y += translation.y

            // Reset the translation to avoid cumulative translation over time
            gesture.setTranslation(.zero, in: imageView)
        }
    }
}
