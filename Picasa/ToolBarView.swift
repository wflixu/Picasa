//
//  ToolBarView.swift
//  Picasa
//
//  Created by 李旭 on 2024/9/15.
//

import SwiftUI

struct ToolBarView: View {
    @State private var showShortcut = false
    
    @EnvironmentObject var appState: AppState
    
    let scale: CGSize
    
    let onTap: (_ actionID: ToolbarActionIdentifier) -> Void
    
    var scaleFormated: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent // 设置百分比格式
        formatter.maximumFractionDigits = 0 // 保留小数位数（可选）
        formatter.minimumFractionDigits = 0 // 最少小数位数（可选）

        if let formattedString = formatter.string(from: NSNumber(value: scale.width)) {
            return formattedString
        } else {
            return ""
        }
    }
    
    var indexFormated: String {
        return "\(appState.selectedImageIndex)/\(appState.imageFiles.count)"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 缩放
            Button(action: {
                self.onTap(ToolbarActionIdentifier.scaleMinis)
            }) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }.buttonStyle(PlainButtonStyle())
            
            Text(scaleFormated).foregroundStyle(.white)
                
            Button(action: {
                self.onTap(.scalePlus)
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }.buttonStyle(PlainButtonStyle())
            
            // 浏览
            Button(action: {
                self.onTap(.showPrev)
            }) {
                Image(systemName: "chevron.left.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }.buttonStyle(PlainButtonStyle())
               
            Text(indexFormated).foregroundStyle(.white)
            
            Button(action: {
                self.onTap(.showNext)
            }) {
                Image(systemName: "chevron.right.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }.buttonStyle(PlainButtonStyle())
            
            Divider()
            // toggle sidebar
            Button(action: {
                self.onTap(.toggleNav)
            }) {
                Image(systemName: "square.leadingthird.inset.filled")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }.buttonStyle(PlainButtonStyle())
            
            // 第一个图标按钮
            Button(action: {
                self.onTap(.toggleInfo)
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding([.leading, .trailing], 10)
        .padding([.top, .bottom], 8)
        .frame(height: 42)
        .background(Color.gray.opacity(0.6))
        .cornerRadius(4)
        .shadow(radius: 2)
    }
}

enum ToolbarActionIdentifier: String, Hashable {
    case scaleMinis
    case scalePlus
    case showPrev
    case showNext
    case toggleNav
    case toggleInfo
}
