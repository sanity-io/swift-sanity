// MIT License
//
// Copyright (c) 2023 Sanity.io

import Sanity
import SwiftUI

@main
struct SanityDemoApp: App {
    static let sanityClient = SanityClient(projectId: "hhpbrwal", dataset: "production", version: .v1, useCdn: true) // Set token to be able to do mutations
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
