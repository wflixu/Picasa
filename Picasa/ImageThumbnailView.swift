//
//  ImageThumbnailView.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/5.
//

import SwiftUI

struct ImageThumbnailView: View {
    let imageURL: URL
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if let image = NSImage(contentsOf: imageURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 90)
                    .border(isSelected ? Color.blue : Color.clear, width: 2)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 120, height: 90)
                    .border(isSelected ? Color.blue : Color.clear, width: 4)
            }
        }
        .padding(5)
    }
}


