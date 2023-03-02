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
        // Retain self when being presented, it is not guarnteed that WalletMode instance
        // will be retained by caller
        let completion: () -> Void = {
            if let presentingViewController = self.bottomSheetViewController.presentingViewController {
                // Calling `dismiss()` on the presenting view controller causes
                // the bottom sheet and any presented view controller by
                // bottom sheet (i.e. Link) to be dismissed all at the same time.
                presentingViewController.dismiss(animated: true)
            }
            self.completion = nil
        }
        self.completion = completion

        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = WalletModeError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            configuration.delegate?.didError(error)
            return
        }
        load() { result in
            switch(result) {
            case .success(let savedPaymentMethods):
                self.present(from: presentingViewController, savedPaymentMethods: savedPaymentMethods)
            case .failure(let error):
                self.configuration.delegate?.didError(.errorFetchingSavedPaymentMethods(error))
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
    var completion: (() -> Void)?
}

extension WalletMode {
    func load(completion: @escaping (Result<[STPPaymentMethod], WalletModeError>) -> Void) {
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
                completion(.failure(.errorFetchingSavedPaymentMethods(error)))
                return
            }
            completion(.success(paymentMethods))
        }

    }

}

extension WalletMode: WalletModeViewControllerDelegate {
    func walletModeViewControllerDidCancel(_ walletModeViewController: WalletModeViewController) {
        walletModeViewController.dismiss(animated: true) {
            self.completion?()
        }
    }

    func walletModeViewControllerDidFinish(_ walletModeViewController: WalletModeViewController) {
        walletModeViewController.dismiss(animated: true) {
            self.completion?()
        }
    }
}


extension WalletMode: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.completion?()
        }
    }
}
