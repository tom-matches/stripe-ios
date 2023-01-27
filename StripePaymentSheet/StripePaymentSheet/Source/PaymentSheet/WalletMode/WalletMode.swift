//
//  WalletMode.swift
//  StripePaymentSheet
//
//  Created by John Woo on 1/26/23.
//

import Foundation
import UIKit
public class WalletMode {
    let configuration: WalletModeConfiguration

    public init(configuration: WalletModeConfiguration) {
        self.configuration = configuration
    }

    public func present(from presentingViewController: UIViewController) {
        if let createSetupIntent = self.configuration.createSetupIntent {
            createSetupIntent() { key in
                guard let key = key else {
                    return
                }
                print("the setup intent key is \(key)")
            }
        }
    }
}
