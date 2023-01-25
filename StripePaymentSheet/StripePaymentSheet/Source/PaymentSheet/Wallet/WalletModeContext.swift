//
//  WalletModeContext.swift
//  StripePaymentSheet
//
//

public protocol WalletModeContext {
    func createCustomerKey(completion: @escaping (String?) -> Void)
    func createSetupIntent(completion: @escaping (String?) -> Void)
    var customerId: String {get}
}
