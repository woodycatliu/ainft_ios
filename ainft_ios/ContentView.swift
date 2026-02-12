//
//  ContentView.swift
//  ainft_ios
//
//  Created by Woody on 2026/2/12.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    private let targetURL = URL(string: "https://ainft.com/")!
//    private let targetURL = URL(string: "https://chat.ainft.com/chat")!

    var body: some View {
        ZStack {
            WebView(url: targetURL, isLoading: $isLoading)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    ContentView()
}
