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

/// TODO -
@frozen public enum WalletModeResult {
    /// TODO
    case completed

    /// The attempt failed.
    /// - Parameter error: The error encountered by the customer. You can display its `localizedDescription` to the customer.
    case failed(error: Error)
}

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
    public func present(from presentingViewController: UIViewController,
                        completion: @escaping (WalletModeResult) -> Void
    ) {
        // Overwrite completion closure to retain self until called
        let completion: (WalletModeResult) -> Void = { status in
            // Dismiss if necessary
            if let presentingViewController = self.bottomSheetViewController.presentingViewController {
                // Calling `dismiss()` on the presenting view controller causes
                // the bottom sheet and any presented view controller by
                // bottom sheet (i.e. Link) to be dismissed all at the same time.
                presentingViewController.dismiss(animated: true) {
                    completion(status)
                }
            } else {
                completion(status)
            }
            self.completion = nil
        }
        self.completion = completion


        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = WalletModeError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failed(error: error))
            return
        }
        load() { result in
            switch(result) {
            case .success(let savedPaymentMethods):
                self.present(from: presentingViewController, savedPaymentMethods: savedPaymentMethods)
            case .failure(let error):
                //TODO: Update error type
                completion(.failed(error: error))
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
    // MARK: - Internal Properties
    var completion: ((WalletModeResult) -> Void)?


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
    func walletModeViewControllerDidFinish(_ walletModeViewController: WalletModeViewController, result: WalletModeResult) {
        walletModeViewController.dismiss(animated: true) {
            self.completion?(result)
        }
    }

    func walletModeViewControllerDidCancel(_ walletModeViewController: WalletModeViewController) {
        walletModeViewController.dismiss(animated: true) {
            self.completion?(.completed)
        }
    }

}


extension WalletMode: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            print("todo")
            //self.completion?(.canceled)
        }
    }
}
