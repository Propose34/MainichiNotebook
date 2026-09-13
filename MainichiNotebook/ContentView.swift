//
//  ContentView.swift
//  MainichiNotebook
//
//  Created by Propose34 on 4/6/2569 BE.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appSettingsService: AppSettingsService

    var body: some View {
        MainAppShellView()
            .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch appSettingsService.settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppSettingsService())
    }
}
