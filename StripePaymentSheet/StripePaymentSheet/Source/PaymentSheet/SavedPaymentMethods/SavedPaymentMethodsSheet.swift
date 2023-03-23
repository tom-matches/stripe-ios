//
//  SavedPaymentMethodSheet.swift
//  StripePaymentSheet
//
//  Created by John Woo on 1/26/23.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

public class SavedPaymentMethodsSheet {
    let configuration: SavedPaymentMethodsSheet.Configuration

    private var savedPaymentMethodsViewController: SavedPaymentMethodsViewController?

    /// The STPPaymentHandler instance
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    lazy var paymentHandler: STPPaymentHandler = { STPPaymentHandler(apiClient: configuration.apiClient, formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler()) }()

    /// The parent view controller to present
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
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
                self?.paymentHandler.cancel3DS2ChallengeFlow()
            }
        )

        if #available(iOS 13.0, *) {
            configuration.style.configure(vc)
        }
        return vc
    }()

    public init(configuration: SavedPaymentMethodsSheet.Configuration) {
        self.configuration = configuration
    }

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public func present(from presentingViewController: UIViewController) {
        // Retain self when being presented, it is not guarnteed that SavedPaymentMethodsSheet instance
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
            let error = SavedPaymentMethodsSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            configuration.delegate?.didError(error)
            return
        }
        loadPaymentMethods() { result in
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
        let loadSpecsPromise = Promise<Void>()
        AddressSpecProvider.shared.loadAddressSpecs {
            loadSpecsPromise.resolve(with: ())
        }
       
        loadSpecsPromise.observe { _ in
            DispatchQueue.main.async {
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay() && self.configuration.applePay != nil
                let savedPaymentSheetVC = SavedPaymentMethodsViewController(savedPaymentMethods: savedPaymentMethods,
                                                                            configuration: self.configuration,
                                                                            isApplePayEnabled: isApplePayEnabled,
                                                                            delegate: self)
                self.bottomSheetViewController.contentStack = [savedPaymentSheetVC]
            }
        }
    }
    // MARK: - Internal Properties
    var completion: (() -> Void)?
}

extension SavedPaymentMethodsSheet {
    func loadPaymentMethods(completion: @escaping (Result<[STPPaymentMethod], SavedPaymentMethodsSheetError>) -> Void) {
        configuration.customerContext.listPaymentMethodsForCustomer {
            paymentMethods, error in
            guard let paymentMethods = paymentMethods, error == nil else {
                // TODO: Pass errors from the customerContext
                let error = PaymentSheetError.unknown(debugDescription: "Failed to retrieve PaymentMethods for the customer")
//                let error = error ?? PaymentSheetError.unknown(
//                    debugDescription: "Failed to retrieve PaymentMethods for the customer"
//                )
                completion(.failure(.errorFetchingSavedPaymentMethods(error)))
                return
            }
            let filteredPaymentMethods = paymentMethods.filter{ $0.type == .card }
            completion(.success(filteredPaymentMethods))
        }

    }

}

extension SavedPaymentMethodsSheet: SavedPaymentMethodsViewControllerDelegate {
    func savedPaymentMethodsViewControllerDidCancel(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController) {
        savedPaymentMethodsViewController.dismiss(animated: true) {
            self.completion?()
        }
    }

    func savedPaymentMethodsViewControllerDidFinish(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController) {
        savedPaymentMethodsViewController.dismiss(animated: true) {
            self.completion?()
        }
    }
}

extension SavedPaymentMethodsSheet: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.completion?()
        }
    }
}


extension STPCustomerContext {
    /// Returns the currently selected Payment Option for this customer context.
    /// You can use this to obtain the selected payment method without loading the SavedPaymentMethodsSheet.
    public func retrieveSelectedPaymentOption(
        completion: @escaping (SavedPaymentMethodsSheet.PaymentOptionSelection?, Error?) -> Void
    ) {
//        TODO: Implement this!
        self.retrieveSelectedPaymentMethodID { _, _ in
            completion(nil, nil)
        }
    }
}
