//
//  CategoryCardView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct CategoryCardView: View {
    @State var category: Category
    
    var body: some View {
        ZStack {
            Image("cookbook-category")
                .resizable()
                .scaledToFit()
                .overlay(
                    VStack {
                        Spacer()
                        Text(category.name == "*" ? "Other" : category.name)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundStyle(.white)
                            .padding()
                    }
                )
                .padding()
        }
    }
}
