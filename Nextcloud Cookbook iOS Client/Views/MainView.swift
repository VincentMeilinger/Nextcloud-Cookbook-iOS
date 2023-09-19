//
//  ContentView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    @StateObject var userSettings: UserSettings
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 0)]
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(viewModel.categories, id: \.name) { category in
                        NavigationLink(
                            destination: RecipeBookView(
                                categoryName: category.name,
                                viewModel: viewModel)
                        ) {
                            CategoryCardView(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("CookBook")
            .toolbar {
                Menu {
                    Button {
                        print("Downloading all recipes ...")
                        Task {
                            await viewModel.downloadAllRecipes()
                        }
                    } label: {
                        HStack {
                            Text("Download all recipes")
                            Image(systemName: "icloud.and.arrow.down")
                        }
                    }
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                NavigationLink( destination: SettingsView(userSettings: userSettings, viewModel: viewModel)) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .task {
            await viewModel.loadCategoryList()
        }
        .refreshable {
            await viewModel.loadCategoryList(needsUpdate: true)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(userSettings: UserSettings())
    }
}








