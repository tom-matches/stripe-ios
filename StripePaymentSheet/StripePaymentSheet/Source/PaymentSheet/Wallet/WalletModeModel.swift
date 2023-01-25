//
//  WalletModeModel.swift
//  StripePaymentSheet
//

@_spi(STP) import StripePayments

public class WalletModeModel {
    let walletModeContext: WalletModeContext
    let paymentHandler: STPPaymentHandler

    // Todo, need to accept type of payment methods we allow as an input to listPaymentMethods
    public init(walletModeContext: WalletModeContext,
         apiClient: STPAPIClient = .shared,
         threeDSCustomizationSettings: STPThreeDSCustomizationSettings = STPThreeDSCustomizationSettings()) {
        self.walletModeContext = walletModeContext
        self.paymentHandler = STPPaymentHandler(apiClient: apiClient,
                                                threeDSCustomizationSettings: threeDSCustomizationSettings,
                                                formSpecPaymentHandler: nil)
    }
/*
    // Currently assumes only cards
    public func listPaymentMethods(customerId: String) {
        walletModeContext.createCustomerKey(customerId: customerId) { ephemeralKey in
            guard let ephemeralKey = ephemeralKey else {
                return
            }
            self.paymentHandler.apiClient.listPaymentMethods(forCustomer: customerId, using: ephemeralKey) { paymentMethods, error in
                guard error == nil,
                    let paymentMethods = paymentMethods else {
                    print("failed to get paymentMethods for customers")
                    return
                }
                print("Found (\(paymentMethods.count))paymentMethods")
                for paymentMethod in paymentMethods {
                    if let card = paymentMethod.card {
                        print(" id: \(paymentMethod.stripeId), last4: \(card.last4 ?? ""), exp: \(card.expMonth)/\(card.expYear)")
                    } else {
                        print(" otherPaymentMethod: \(paymentMethod.stripeId)")
                    }
                }
            }
        }
    }
    public func detachPaymentMethod(paymentMethodId: String, customerId: String) {
        walletModeContext.createCustomerKey(customerId: customerId) { ephemeralKey in
            guard let ephemeralKey = ephemeralKey else {
                return
            }
            self.paymentHandler.apiClient.detachPaymentMethod(paymentMethodId, fromCustomerUsing: ephemeralKey){ error in
                guard error == nil else {
                    print("Failed to detach payment method")
                    return
                }                
            }
        }
    }
 */
}
