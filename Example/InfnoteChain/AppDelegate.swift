//
//  AppDelegate.swift
//  InfnoteChain
//
//  Created by Vergil Choi on 09/28/2018.
//  Copyright (c) 2018 Vergil Choi. All rights reserved.
//

import UIKit
import InfnoteChain

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        procedure()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

func procedure() {
    guard let peer = Peer(address: "echo.websocket.org") else {
        return
    }
    Connection(peer)
        .handled(by: ConnectionObserver
            .onConnected { conn in
                print("Success to connect host \(conn.peer.address).")
                sendHello(conn)
            }
            .onDisconnected { e, conn in
                print("Disconnected from \(conn.peer.address).")
                if let error = e {
                    print(error)
                }
            }
        )
        .connect()
}

func sendHello(_ conn: Connection) {
    print("Sending a Hello message...")
    let msg = Message(type: .hello, content: ["payload": "Hello"])
    Courier(msg).send(through: conn).handled(by: .onResponse { content in
        print("Receive message:", content)
        Thread.sleep(forTimeInterval: 2)
        conn.disconnect()
    })
}
