//
//  Spoof_Device_DetectorApp.swift
//  Spoof Device Detector
//
//  Created by Jakub Dolejs on 08/04/2025.
//

import SwiftUI

@main
struct Spoof_Device_DetectorApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
            }
        }
    }
}

func measure<T>(_ block: () async throws -> T) async -> (Result<T,Error>, Double) {
    let start = CFAbsoluteTimeGetCurrent()
    var result: Result<T,Error>!
    do {
        result = .success(try await block())
    } catch {
        result = .failure(error)
    }
    let duration: Double = CFAbsoluteTimeGetCurrent() - start
    return (result, duration)
}
