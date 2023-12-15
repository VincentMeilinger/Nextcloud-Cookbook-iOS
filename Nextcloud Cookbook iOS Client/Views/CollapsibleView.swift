//
//  CollapsibleView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.12.23.
//

import Foundation
import SwiftUI

struct CollapsibleView<C: View, T: View>: View {
    @State var titleColor: Color = .white
    @State var isCollapsed: Bool = true
    
    @State var content: () -> C
    @State var title: () -> T
    
    @State private var rotationAngle: Double = -90
    
    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCollapsed.toggle()
                    if isCollapsed {
                        rotationAngle += 90
                    } else {
                        rotationAngle -= 90
                    }
                }
                rotationAngle = isCollapsed ? -90 : 0
            } label: {
                HStack {
                    Image(systemName: "chevron.down")
                        .bold()
                        .rotationEffect(Angle(degrees: rotationAngle))
                    title()
                }.foregroundStyle(titleColor)
            }
            
            if !isCollapsed {
                content()
                    .padding(.top)
            }
        }
        .onAppear {
            rotationAngle = isCollapsed ? -90 : 0
        }
    }
}
