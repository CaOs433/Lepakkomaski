//
//  Lepakkomaski_v1App.swift
//  Lepakkomaski-v1 WatchKit Extension
//
//  Created by Oskari Saarinen on 8.12.2020.
//

import SwiftUI

@main
struct Lepakkomaski_v1App: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
