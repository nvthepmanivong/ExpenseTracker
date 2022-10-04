//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Nino Thepmanivong on 8/26/22.
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject var transactionListVM = TransactionListViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(transactionListVM)
        }
    }
}
