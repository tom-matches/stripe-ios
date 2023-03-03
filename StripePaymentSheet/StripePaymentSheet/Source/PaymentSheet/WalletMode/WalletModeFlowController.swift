//
//  WalletModeFlowController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension WalletMode {

    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public class FlowController: WalletModeViewControllerDelegate {
        public let configuration: Configuration
        private let savedPaymentMethods: [STPPaymentMethod]

        public var paymentOption: PaymentOptionSelection? {
            if let selectedPaymentOption = _paymentOption {
                if case .saved(let pm) = selectedPaymentOption {
                    // TODO: We should clean this up similar to how flow controller does it for consistencypm.stripeId
                    return PaymentOptionSelection(paymentMethodId: pm.stripeId,
                                                  displayData: WalletMode.PaymentOptionSelection.PaymentOptionDisplayData(image: pm.makeIcon(),
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

        private lazy var paymentOptionsViewController: WalletModeViewController = {
            let walletModeViewController = WalletModeViewController(savedPaymentMethods: savedPaymentMethods,
                                                                    configuration: configuration,
                                                                    delegate: self)
            return walletModeViewController
        }()

        required init(
            savedPaymentMethods: [STPPaymentMethod],
            configuration: Configuration            
        ) {
            self.savedPaymentMethods = savedPaymentMethods
            self.configuration = configuration
        }

        /// MARK - WalletModeViewControllerDelegate
        func walletModeViewControllerDidCancel(_ walletModeViewController: WalletModeViewController) {  }
        func walletModeViewControllerDidFinish(_ walletModeViewController: WalletModeViewController) {  }
    }

}
