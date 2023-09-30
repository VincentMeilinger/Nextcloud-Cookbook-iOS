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
            Image("CookBook")
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    VStack {
                        Spacer()
                        Color.clear
                            .background(
                                .ultraThickMaterial
                            )
                            .overlay(
                                Text(category.name == "*" ? "Other" : category.name)
                                    .font(.headline)
                            )
                            .frame(maxHeight: 25)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
    }
}
