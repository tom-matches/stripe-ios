//
//  MyWalletModeContext.swift
//  PaymentSheet Example
//
//

//import Foundation
import Stripe
import StripePaymentSheet
class MyWalletModeContext: WalletModeContext {

    func createCustomerKey(completion: @escaping (String?) -> Void) {
        let body = [ "customer_id": self.customerId] as [String: Any]
        let url = URL(string: "https://pool-seen-sandal.glitch.me/create_customer_ephemeral_key")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, response, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print(error as Any)
                return
            }
            guard let customerEphemeralKey = json["secret"] as? String else {
                print("Failed to get secret")
                return
            }
            completion(customerEphemeralKey)
        }
        task.resume()
    }
    func createSetupIntent(completion: @escaping (String?) -> Void) {
        let body = [ "a": "b"
        ] as [String: Any]
        let url = URL(string: "https://pool-seen-sandal.glitch.me/create_setup_intent")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, response, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print(error as Any)
                return
            }
            guard let clientSecret = json["client_secret"] as? String else {
                print("failed")
                return
            }
            completion(clientSecret)
        }
        task.resume()
    }
    public let customerId: String
    init(customerId: String) {
        self.customerId = customerId
    }
}
