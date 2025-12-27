//
//  ContentView.swift
//  formula
//
//  Created by Neil Chulani on 12/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = TelemetryViewModel()

    var body: some View {
        TelemetryRootView(model: model)
            .frame(minWidth: 1080, minHeight: 760)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
