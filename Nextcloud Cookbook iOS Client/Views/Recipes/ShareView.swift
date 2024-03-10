//
//  ShareView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 17.02.24.
//

import Foundation
import SwiftUI


struct ShareView: View {
    @State var recipeDetail: RecipeDetail
    @State var recipeImage: UIImage?
    @Binding var presentShareSheet: Bool
    
    @State var exporter = RecipeExporter()
    @State var sharedURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if let url = sharedURL {
                    ShareLink(item: url, subject: Text("PDF Document")) {
                        Image(systemName: "doc")
                        Text("Share as PDF")
                    }
                    .foregroundStyle(.primary)
                    .bold()
                    .padding()
                }
                
                ShareLink(item: exporter.createText(recipe: recipeDetail), subject: Text("Recipe")) {
                    Image(systemName: "ellipsis.message")
                    Text("Share as text")
                }
                .foregroundStyle(.primary)
                .bold()
                .padding()
                
                /*ShareLink(item: exporter.createJson(recipe: recipeDetail), subject: Text("Recipe")) {
                 Image(systemName: "doc.badge.gearshape")
                 Text("Share as JSON")
                 }
                 .foregroundStyle(.primary)
                 .bold()
                 .padding()
                 */
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        presentShareSheet = false
                    }
                }
            }
        }
        .task {
            self.sharedURL = exporter.createPDF(recipe: recipeDetail, image: recipeImage)
        }
        
        
    }
}
