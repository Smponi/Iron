//
//  SceneDelegate.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import UIKit
import SwiftUI
import WorkoutDataKit
import CoreData
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var sceneState = SceneState()
    
    private var urlContexts: Set<UIOpenURLContext>?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: ContentView().environmentObject(sceneState))
            self.window = window
            window.makeKeyAndVisible()
        }
        
        urlContexts = connectionOptions.urlContexts // handle later because the view is not ready to handle input yet
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURLContexts(urlContexts: URLContexts)
    }
    
    private func handleURLContexts(urlContexts: Set<UIOpenURLContext>) {
        // NOTE: currently, if for some reason there is more than 1 url context, we only process one of them
        
        if let urlContext = urlContexts.first(where: { $0.url.isFileURL }) {
            urlContext.url.downloadFile { result in
                do {
                    switch result {
                    case .success():
                        guard let backupData = try Self.urlData(url: urlContext.url, openInPlace: urlContext.options.openInPlace) else { return }
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .RestoreFromBackup, object: self, userInfo: [restoreFromBackupDataUserInfoKey : backupData])
                        }
                    case .failure(let error):
                        throw error
                    }
                } catch {
                    print(error)
                }
            }
        } else if let urlContext = urlContexts.first(where: { $0.url.isDeepLinkURL }) {
            if urlContext.url.host == DeepLink.startWorkout.rawValue {
                let context = WorkoutDataStorage.shared.persistentContainer.viewContext
                do {
                    let count = try context.count(for: Workout.currentWorkoutFetchRequest)
                    if count == 0 {
                        let workout = Workout.create(context: context)
                        do {
                            os_log("Starting workout from deep link URL", log: .workoutData)
                            try workout.start(startWatchCompanionErrorHandler: { error in
                                // the Apple Watch wasn't started, most probably because the app is in the background
                                os_log("Sending user notification to open the app because the watch app wasn't started. Probably because the app is in the background", log: .watch)
                                NotificationManager.shared.requestStartedWorkoutFromBackgroundNotification()
                            })
                        } catch {
                            os_log("Could not start workout: %@", log: .workoutData, type: .error, NSManagedObjectContext.descriptionWithDetailedErrors(error: error as NSError))
                            context.delete(workout)
                        }
                    }
                } catch {
                    os_log("Could not get count of workouts", log: .workoutData, type: .error)
                }
                sceneState.selectedTab = .workout
            }
        }
    }
    
    private static func urlData(url: URL, openInPlace: Bool) throws -> Data? {
        if openInPlace {
            guard url.startAccessingSecurityScopedResource() else {
                print("openInPlace but startAccessingSecurityScopedResource() -> false")
                return nil
            }
        }
        defer {
            if openInPlace {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try Data(contentsOf: url)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        // the urls come from scene will connect, but they are handled here
        if let urlContexts = urlContexts {
            self.urlContexts = nil // don't process them again
            self.handleURLContexts(urlContexts: urlContexts)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        OSLog.default.trace()
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        // prepareAndStartWatchWorkout() only works when the app is active (not in background), therefore it could be that we have to call it now
        if SettingsStore.shared.watchCompanion && WatchConnectionManager.shared.currentWatchWorkoutUuid == nil {
            // if the watch companion is enabled and we haven't (successfully) started a watch workout yet
            do {
                // check if we have a workout running
                os_log("Watch companion is enabled and no watch workout was started, checking if we have a current workout", log: .watch)
                if let currentWorkout = try WorkoutDataStorage.shared.persistentContainer.viewContext.fetch(Workout.currentWorkoutFetchRequest).first {
                    os_log("Current workout exists, but no watch workout was started. Trying to start it now.", log: .watch)
                    WatchConnectionManager.shared.prepareAndStartWatchWorkout(workout: currentWorkout)
                }
            } catch {
                os_log("Could not fetch current workout: %@", log: .workoutData, type: .error, NSManagedObjectContext.descriptionWithDetailedErrors(error: error as NSError))
            }
        }

        NotificationManager.shared.notificationCenter.removeAllDeliveredNotifications()
        NotificationManager.shared.removePendingNotificationRequests(withIdentifiers: [.unfinishedWorkout])
        
        NotificationManager.shared.removePendingNotificationRequests(withIdentifiers: [.unfinishedTraining]) // TODO: remove unfinishedTraining in future version
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save changes in the application's managed object context when the application transitions to the background.
        os_log("Scene did enter background, saving workout data", log: .default)
        WorkoutDataStorage.shared.persistentContainer.viewContext.saveOrCrash()
        
        if let currentWorkout = try? WorkoutDataStorage.shared.persistentContainer.viewContext.fetch(Workout.currentWorkoutFetchRequest).first {
            if currentWorkout.hasCompletedSets ?? false { // allows the user to prefill a workout without getting the notification
                // remind the user about his unfinished workout
                NotificationManager.shared.requestUnfinishedWorkoutNotification()
            }
        }
    }
}

class SceneState: ObservableObject {
    @Published var selectedTabNumber: Int = Tab.workout.rawValue
    
    var selectedTab: Tab {
        get {
            Tab(rawValue: selectedTabNumber) ?? Tab.feed
        }
        set {
            selectedTabNumber = newValue.rawValue
        }
    }
    
    enum Tab: Int {
        case feed
        case history
        case workout
        case exercises
        case settings
    }
}
