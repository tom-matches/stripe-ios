//
//  SavedPaymentMethodsSheetFlowController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension SavedPaymentMethodsSheet {

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    class FlowController: SavedPaymentMethodsViewControllerDelegate {
        public let configuration: Configuration
        private let savedPaymentMethods: [STPPaymentMethod]

        public var paymentOption: PaymentOptionSelection? {
            if let selectedPaymentOption = _paymentOption {
                if case .saved(let pm) = selectedPaymentOption {
                    // TODO: We should clean this up similar to how flow controller does it for consistencypm.stripeId
                    return PaymentOptionSelection(paymentMethodId: pm.stripeId,
                                                  displayData: SavedPaymentMethodsSheet.PaymentOptionSelection.PaymentOptionDisplayData(image: pm.makeIcon(),
                                                                                                                          label: pm.paymentSheetLabel))
                }
            }
            return nil
        }

        private var _paymentOption: PaymentOption? {
            guard paymentOptionsViewController.error == nil else {
                return nil
            }
            return paymentOptionsViewController.selectedPaymentOption
        }

        private lazy var paymentOptionsViewController: SavedPaymentMethodsViewController = {
            return SavedPaymentMethodsViewController(savedPaymentMethods: savedPaymentMethods,
                                                     configuration: configuration,
                                                     delegate: self)
        }()

        required init(
            savedPaymentMethods: [STPPaymentMethod],
            configuration: Configuration            
        ) {
            self.savedPaymentMethods = savedPaymentMethods
            self.configuration = configuration
        }

        /// MARK - WalletModeViewControllerDelegate
        func savedPaymentMethodsViewControllerDidCancel(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController) {  }
        func savedPaymentMethodsViewControllerDidFinish(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController) {  }
    }

}
