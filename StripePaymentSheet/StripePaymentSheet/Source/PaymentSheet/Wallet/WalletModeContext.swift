//
//  WalletModeContext.swift
//  StripePaymentSheet
//
//

public protocol WalletModeContext {
    func createCustomerKey(customerId: String, completion: @escaping (String?) -> Void)
    func createSetupIntent(completion: @escaping (String?) -> Void)
}
