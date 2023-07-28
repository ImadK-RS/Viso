//
//  ProFlixApp.swift
//  ProFlix
//
//  Created by Anil Solanki on 19/02/23.
//

import SwiftUI

@main
struct ProFlixApp: App {
  @StateObject var coreData = CoreDataEnvironmentObject()
  @StateObject var appState = AppState()

  var body: some Scene {
    WindowGroup {
      ProFlixRootView()
        .environmentObject(coreData)
        .environmentObject(appState)
    }
  }
}
