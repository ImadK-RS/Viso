//
//  ProFlixRootView.swift
//  ProFlix
//
//  Created by Anil Solanki on 19/02/23.
//

import SwiftUI

struct ProFlixRootView: View {

  @AppStorage(Const.defaultKeys.user_eula_agreed_key, store: .standard) var userAgreedEula: Bool =
    false
  @EnvironmentObject var appState: AppState
  @StateObject var router = NavRouter()

  var body: some View {
    Group {
      if !userAgreedEula {
        // Show EULA first
        EmptyView()
      } else {
        // After EULA, check authentication
        if appState.isAuthenticated {
          // Show Xtream content tabs
          XtreamMainView()
            .environmentObject(router)
        } else {
          // Show login screen
          LoginView()
        }
      }
    }
    .sheet(isPresented: $userAgreedEula.not) {
      UserAgreementView()
        .interactiveDismissDisabled(true)
    }
  }
}

struct ProFlixRootView_Previews: PreviewProvider {
  static var previews: some View {
    ProFlixRootView()
  }
}

extension Binding where Value == Bool {
  var not: Binding<Value> {
    Binding<Value>(
      get: { !self.wrappedValue },
      set: { self.wrappedValue = !$0 }
    )
  }
}
