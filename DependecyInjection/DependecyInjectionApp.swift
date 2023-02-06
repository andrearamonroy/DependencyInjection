//
//  DependecyInjectionApp.swift
//  DependecyInjection
//
//  Created by Andrea Monroy on 2/2/23.
//

import SwiftUI

@main
struct DependecyInjectionApp: App {
    //customize init 
    let dataService = ProductionDataService(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
    var body: some Scene {
        WindowGroup {
            ContentView(dataService: dataService)
        }
    }
}
