//
//  SceneDelegate.swift
//  FNote
//
//  Created by Dara Beng on 8/26/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
    
        // setup app state
        let parentContext = CoreDataStack.current.mainContext
        let userPreference = UserPreference.shared
        let appState = AppState(parentContext: parentContext)
        appState.noteCardSortOption = userPreference.noteCardSortOption
        appState.noteCardSortOptionAscending = userPreference.noteCardSortOptionAscending
        appState.fetchCurrentNoteCards()
        
        // create window
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // setup appearance
        window.tintColor = .appAccent
        userPreference.setColorScheme(for: window)
        UISwitch.appearance().onTintColor = .appAccent
        
        // setup home view
        let homeView = HomeView()
            .environmentObject(appState)
            .environmentObject(userPreference)
            .environment(\.managedObjectContext, appState.parentContext)
        
        let rootViewCV = UIHostingController(rootView: homeView)
        
        window.rootViewController = rootViewCV
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}

