//
//  TransactionListViewModel.swift
//  ExpenseTracker
//
//  Created by Nino Thepmanivong on 9/14/22.
//

import Foundation
import Combine
import Collections

// Dictionaries are unordered by default; Recent transactions by most recent
typealias TransactionGroup = OrderedDictionary<String, [Transaction]>
typealias TransactionPrefixSum = [(String, Double)]

final class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        getTransactions()
    }

func getTransactions() {
    // 'guard' checks if it is valid. Else, print 'invalid URL'
    guard let url = URL(string: "https://www.designcode.io/data/transactions.json") else {
        print("Invalid URL")
        return
    }
    
    // fetches data from an API
    URLSession.shared.dataTaskPublisher(for: url)
        .tryMap { (data, response) -> Data in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // if there's an error
                dump(response)
                throw URLError(.badServerResponse)
            }
            
            return data
        }
        .decode(type: [Transaction].self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink { completion in
            switch completion {
            case .failure(let error):
                print("Error fetching transactions:", error.localizedDescription)
            case .finished:
                print("Finished fetching transactions.")
            }
        } receiveValue: { [weak self] result in
            self?.transactions = result
        }
        .store(in: &cancellables)

    }
    
    func groupTransactionsByMonth() -> TransactionGroup {
        //make sure the Transactionsarray is not empty
        guard !transactions.isEmpty else {return [:]}
            let groupedTransactions = TransactionGroup(grouping: transactions) {$0.month}
            
            return groupedTransactions
        }
    
    func accumulateTransactions() -> TransactionPrefixSum {
        
        print ("accumulateTransactions")
        guard !transactions.isEmpty else { return [] }
        
        let today = "02/17/2022".dateParsed()  // dateParsed() converts to Swift date;
        let dateInterval = Calendar.current.dateInterval(of: .month, for: today)!
        print("dateInterval", dateInterval)
        
        var sum: Double = .zero
        var cumulativeSum = TransactionPrefixSum()
        
        for date in stride(from: dateInterval.start, to: today, by: 60*60*24) {
            let dailyExpenses = transactions.filter { $0.dateParsed == date && $0.isExpense }
            let dailyTotal = dailyExpenses.reduce(0) { $0 - $1.signedAmount }
            
            sum += dailyTotal
            sum = sum.roundedTo2Digits()
            cumulativeSum.append((date.formatted(), sum))
            print(date.formatted(), "dailyTotal:", dailyTotal, "sum:", sum)
            
        }
        return cumulativeSum
    }
}
