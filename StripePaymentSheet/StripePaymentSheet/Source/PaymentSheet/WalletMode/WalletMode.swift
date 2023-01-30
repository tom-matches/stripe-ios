//
//  WalletMode.swift
//  StripePaymentSheet
//
//  Created by John Woo on 1/26/23.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

public class WalletMode {
    let configuration: WalletMode.Configuration

    lazy var bottomSheetViewController: BottomSheetViewController = {
        let isTestMode = configuration.apiClient.isTestmode
        let loadingViewController = LoadingViewController(
            delegate: self,
            appearance: configuration.appearance,
            isTestMode: isTestMode
        )

        let vc = BottomSheetViewController(
            contentViewController: loadingViewController,
            appearance: configuration.appearance,
            isTestMode: isTestMode,
            didCancelNative3DS2: { [weak self] in
                // TODO: Probably needed due to.. 3ds2 w/ cards
//                self?.paymentHandler.cancel3DS2ChallengeFlow()
            }
        )

        if #available(iOS 13.0, *) {
            configuration.style.configure(vc)
        }
        return vc
    }()

    public init(configuration: WalletMode.Configuration) {
        self.configuration = configuration
    }

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public func present(from presentingViewController: UIViewController) {
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            return
        }
        load() { result in
            switch(result) {
            case .success(let savedPaymentMethods):
                self.present(from: presentingViewController, savedPaymentMethods: savedPaymentMethods)
            case .failure(let error):
                // TODO: Figure out how we present errors
                print("error: \(error)")
                return
            }
        }
        presentingViewController.presentAsBottomSheet(bottomSheetViewController,
                                                      appearance: configuration.appearance)
    }

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    func present(from presentingViewController: UIViewController,
                 savedPaymentMethods: [STPPaymentMethod]) {
        let walletViewController = WalletModeViewController(savedPaymentMethods: savedPaymentMethods,
                                                            configuration: self.configuration,
                                                            delegate: self)
        self.bottomSheetViewController.contentStack = [walletViewController]
    }


}

extension WalletMode {
    enum LoadingResult {
        case success(
            savedPaymentMethods: [STPPaymentMethod]
        )
        case failure(Error)
    }

    func load(completion: @escaping (LoadingResult) -> Void) {
        let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card]
        let customerId = configuration.customer.id
        let ephemeralKey = configuration.customer.ephemeralKeySecret

        configuration.apiClient.listPaymentMethods(
            forCustomer: customerId,
            using: ephemeralKey,
            types: savedPaymentMethodTypes
        ) { paymentMethods, error in
            guard let paymentMethods = paymentMethods, error == nil else {
                let error = error ?? PaymentSheetError.unknown(
                    debugDescription: "Failed to retrieve PaymentMethods for the customer"
                )
                completion(.failure(error))
                return
            }
            completion(.success(savedPaymentMethods: paymentMethods))
        }

    }

}

extension WalletMode: WalletModeViewControllerDelegate {

}


extension WalletMode: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            print("todo")
            //self.completion?(.canceled)
        }
    }
}
