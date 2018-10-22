//
//  TodayViewController.swift
//  ForexWidget
//
//  Created by Samantha Gatt on 10/22/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import NotificationCenter
import ForexCore

class TodayViewController: UIViewController, NCWidgetProviding {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        switch activeDisplayMode {
        case .compact:
            preferredContentSize = maxSize
            self.rateHistoryView.isHidden = true
        case .expanded:
            preferredContentSize = CGSize(width: maxSize.width, height: 200)
            self.rateHistoryView.isHidden = false
        }
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        
        fetcher.fetchCurrentExchangeRate(for: symbol) { (rate, error) in
            if let error = error {
                NSLog("Error fetching current exchange rate: \(error)")
                completionHandler(.failed)
                return
            }
            
            guard let rate = rate else {
                completionHandler(.noData)
                return
            }
            
            DispatchQueue.main.async {
                let rateString = self.currencyFormatter.string(from: rate.rate as NSNumber) ?? "N/A"
                self.currencyLabel.text = rateString + " \(rate.symbol) = 1 \(rate.base)"
            }
            completionHandler(.newData)
        }
        
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        var components = DateComponents()
        components.calendar = calendar
        components.year = -1
        let aYearAgo = calendar.date(byAdding: components, to: now)!
        
        fetcher.fetchExchangeRates(startDate: aYearAgo, symbols: [symbol]) { (rates, error) in
            if let error = error {
                NSLog("Error fetching historical exchange rates: \(error)")
                return
            }
            
            guard let rates = rates else { return }
            
            DispatchQueue.main.async {
                self.rateHistoryView.exchangeRates = rates
            }
        }
    }
    
    private let groupUserDefaults = UserDefaults(suiteName: "group.com.SamanthaGatt.Forex")!
    private let fetcher = ExchangeRateFetcher()
    private var symbol: String {
        return groupUserDefaults.string(forKey: "LastViewedSymbol") ?? "EUR"
    }
    private let currencyFormatter: NumberFormatter = {
        let result = NumberFormatter()
        
        result.numberStyle = .decimal
        result.maximum = 2
        result.minimum = 1
        
        return result
    }()
    
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var rateHistoryView: RateHistoryView!
    
}
