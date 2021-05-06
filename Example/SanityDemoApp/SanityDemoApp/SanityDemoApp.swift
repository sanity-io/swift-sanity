// MIT License
//
// Copyright (c) 2021 Sanity.io

import Sanity
import SwiftUI

@main
struct SanityDemoApp: App {
    static let sanityClient = SanityClient(projectId: "hhpbrwal", dataset: "production", version: .v1)
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
