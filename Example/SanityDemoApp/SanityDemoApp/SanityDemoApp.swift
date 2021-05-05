//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

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
