//
//  AppDelegate.swift
//  musictime
//
//  Created by Aamax Lee on 18/4/2024.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var databaseController: DatabaseProtocol?   // Database controller instance to manage database operations
    var window: UIWindow?
    
    var notificationsEnabled = false        //flag to indicate if notifications are enabled
    // Constants for notification identifiers
    static let NOTIFICATION_IDENTIFIER = "Monash.edu.musictime"
    static let CATEGORY_IDENTIFIER = "Monash.edu.musictime.category"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        databaseController = FirebaseController()   //initialize the database controller
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
         
            
        var initialViewController: UIViewController
//        Check if the user is signed in and set the appropriate initial view controller
        if AuthManager.shared.isSignedIn {
            initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
        } else {
            initialViewController = storyboard.instantiateViewController(withIdentifier: "WelcomeNavigationController")
        }
            
        // Set the initial view controller
        window.rootViewController = initialViewController
        window.makeKeyAndVisible()
        
        self.window = window
        
//        Request notification authorization
        Task {
            let notificationCenter = UNUserNotificationCenter.current()
            let notificationSettings = await notificationCenter.notificationSettings()
            if notificationSettings.authorizationStatus == .notDetermined {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert])
                if granted {
                    self.notificationsEnabled = true
                    scheduleNotificationForNextNoon()
                } else {
                    self.notificationsEnabled = false
                }

            }
            else if notificationSettings.authorizationStatus == .authorized {
                self.notificationsEnabled = true
                scheduleNotificationForNextNoon()
            }
        }
        
//        code below for notifications with actions, but we are not making use of them
            let acceptAction = UNNotificationAction(identifier: "accept", title: "Accept", options: .foreground)

            let declineAction = UNNotificationAction(identifier: "decline", title: "Decline", options: .destructive)
            let commentAction = UNTextInputNotificationAction(identifier: "comment", title: "Comment", options: .authenticationRequired, textInputButtonTitle: "Send", textInputPlaceholder: "Share your thoughts..")
 
            let appCategory = UNNotificationCategory(identifier: AppDelegate.CATEGORY_IDENTIFIER, actions: [acceptAction, declineAction, commentAction], intentIdentifiers: [], options: UNNotificationCategoryOptions(rawValue: 0))

            // Register the category just created with the notification centre
            UNUserNotificationCenter.current().setNotificationCategories([appCategory])

        UNUserNotificationCenter.current().delegate = self
        
        //Request location authorization for Ticketmaster
        TicketmasterLocationManager.shared.requestLocationAuthorization()
        return true
    }
    
     
    
//
    
    func scheduleNotificationForNextNoon() {
        guard self.notificationsEnabled else {
            print("Notifications not enabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Check Video Upload Streak"
        content.body = "Don't forget to upload a video today!"
        content.sound = UNNotificationSound.default
        
        // Calculate the time until the next 12 PM
           let currentDate = Date()
           let calendar = Calendar.current
           var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
           components.hour = 12
           components.minute = 00
           components.second = 0
           
           if let nextNoon = calendar.date(from: components) {
               if nextNoon <= currentDate {
                   // If the scheduled time has already passed for today, add one day to the date components
                   components.day! += 1
               }
               
               let nextFireDate = calendar.date(from: components)!
               let timeInterval = nextFireDate.timeIntervalSince(currentDate)
               
               // Schedule the notification using UNTimeIntervalNotificationTrigger
               let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
               
               let request = UNNotificationRequest(identifier: AppDelegate.NOTIFICATION_IDENTIFIER, content: content, trigger: trigger)
               
               UNUserNotificationCenter.current().add(request) { error in
                   if let error = error {
                       print("Error scheduling notification: \(error)")
                   } else {
                       print("Notification scheduled successfully", timeInterval)
                   }
               }
           }
       }
 


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


    // MARK: UNUserNotificationCenterDelegate methods

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        
//        return [.banner]
        return [ .sound, .badge, .banner]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        
        if response.notification.request.content.categoryIdentifier == AppDelegate.CATEGORY_IDENTIFIER {
            switch response.actionIdentifier {
                case "accept":
                    print("accepted")
                case "decline":
                    print("declined")
                case "comment":
                    if let userResponse = response as? UNTextInputNotificationResponse {
                        print("Response: \(userResponse.userText)")
                        UserDefaults.standard.set(userResponse.userText, forKey: "response")
                    }
                default:
                    print("other")
            }
        }
        else {
            print("General notification")
        }    }
    
}
 
