//
//  SavedPaymentMethodSheetTestPlayground.swift
//  PaymentSheet Example
//
//  ⚠️🏗 This is a playground for internal Stripe engineers to help us test things, and isn't
//  an example of what you should do in a real app!
//  Note: Do not import Stripe using `@_spi(STP)` in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.

import Foundation
import Contacts
import PassKit
import StripePaymentSheet
import SwiftUI
import UIKit

class SavedPaymentMethodSheetTestPlayground: UIViewController {
    static let endpointSelectorEndpoint = "https://stripe-mobile-payment-sheet-test-playground-v6.glitch.me/endpoints"
    static let defaultSavedPaymentMethodEndpoint = "https://pool-seen-sandal.glitch.me"
    //"https://stripe-mobile-payment-sheet-test-playground-v6.glitch.me/saved_payment_method"

    static var paymentSheetPlaygroundSettings: SavedPaymentMethodSheetPlaygroundSettings?

    // Configuration
    @IBOutlet weak var customerModeSelector: UISegmentedControl!
    @IBOutlet weak var shippingInfoSelector: UISegmentedControl!
    @IBOutlet weak var defaultBillingAddressSelector: UISegmentedControl!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var selectingSavedCustomHeaderTextField: UITextField!

    @IBOutlet weak var selectPaymentMethodImage: UIImageView!
    @IBOutlet weak var selectPaymentMethodButton: UIButton!
    @IBOutlet weak var shippingAddressButton: UIButton!

    var walletMode: WalletMode?
    var paymentOptionSelection: WalletMode.PaymentOptionSelection?

    enum CustomerMode: String, CaseIterable {
        case new
        case returning
    }

    enum ShippingMode {
        case on
        case onWithDefaults
        case off
    }

    var customerMode: CustomerMode {
        switch customerModeSelector.selectedSegmentIndex {
        case 0:
            return .new
        default:
            return .returning
        }
    }

    var shouldSetDefaultBillingAddress: Bool {
        return defaultBillingAddressSelector.selectedSegmentIndex == 0
    }

    var customerConfiguration: WalletMode.CustomerConfiguration? {
        if let customerID = customerId,
           let ephemeralKey = ephemeralKey {
            return WalletMode.CustomerConfiguration(
                id: customerID, ephemeralKeySecret: ephemeralKey)
        }
        return nil
    }

    var shippingMode: ShippingMode {
        switch shippingInfoSelector.selectedSegmentIndex {
        case 0: return .on
        case 1: return .onWithDefaults
        default: return .off
        }
    }
    var backend: WalletModeBackend!

    var configuration: WalletMode.Configuration? {
        guard let customerConfiguration = customerConfiguration,
              let customerId = self.customerId else {
            return nil
        }
        var configuration = WalletMode.Configuration(customer: customerConfiguration,
                                                     createSetupIntentHandler: { completionBlock in
            self.backend.createSetupIntent(customerId: customerId,
                                           completion: completionBlock)
        })

        configuration.customer = customerConfiguration
        configuration.appearance = appearance
        configuration.delegate = self

        if shouldSetDefaultBillingAddress {
            configuration.defaultBillingDetails.name = "Jane Doe"
            configuration.defaultBillingDetails.email = "foo@bar.com"
            configuration.defaultBillingDetails.phone = "+13105551234"
            configuration.defaultBillingDetails.address = .init(
                city: "San Francisco",
                country: "CA",
                line1: "510 Townsend St.",
                postalCode: "94102",
                state: "California"
            )
        }
        if shippingMode != .off {
            configuration.shippingDetails = { [weak self] in
                return self?.addressDetails
            }
        }
        // TODO: Get selectingSavedCustomerHeaderText
        return configuration
    }

    var addressConfiguration: AddressViewController.Configuration? {
        guard let walletModeConfig = configuration else {
            return nil
        }
        var addrConfiguration = AddressViewController.Configuration(additionalFields: .init(phone: .optional),
                                                                appearance: walletModeConfig.appearance)
        if case .onWithDefaults = shippingMode {
            addrConfiguration.defaultValues = .init(
                address: .init(
                    city: "San Francisco",
                    country: "US",
                    line1: "510 Townsend St.",
                    postalCode: "94102",
                    state: "California"
                ),
                name: "Jane Doe",
                phone: "5555555555"
            )
            addrConfiguration.allowedCountries = ["US", "CA", "MX", "GB"]
        }
        addrConfiguration.additionalFields.checkboxLabel = "Save this address for future orders"
        return addrConfiguration
    }

    var addressDetails: AddressViewController.AddressDetails?

    var ephemeralKey: String?
    var customerId: String?
    var savedPaymentMethodEndpoint: String = defaultSavedPaymentMethodEndpoint
//    var walletModeFlowController: WalletMode.FlowController?
    var addressViewController: AddressViewController?
    var appearance = PaymentSheet.Appearance.default

    func makeAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: "Complete", message: "Completed", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        return alertController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        checkoutButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
//        checkoutButton.isEnabled = false

        shippingAddressButton.addTarget(self, action: #selector(didTapShippingAddressButton), for: .touchUpInside)
        shippingAddressButton.titleLabel?.adjustsFontSizeToFitWidth = true
        shippingAddressButton.titleLabel?.textAlignment = .right
        shippingAddressButton.isEnabled = false

        loadButton.addTarget(self, action: #selector(load), for: .touchUpInside)

        selectPaymentMethodButton.isEnabled = false
        selectPaymentMethodButton.addTarget(
            self, action: #selector(didTapSelectPaymentMethodButton), for: .touchUpInside)

//        checkoutInlineButton.addTarget(
//            self, action: #selector(didTapCheckoutInlineButton), for: .touchUpInside)
//        checkoutInlineButton.isEnabled = false

        if let paymentSheetPlaygroundSettings = SavedPaymentMethodSheetTestPlayground.paymentSheetPlaygroundSettings {
            loadSettingsFrom(settings: paymentSheetPlaygroundSettings)
        } else if let nsUserDefaultSettings = settingsFromDefaults() {
            loadSettingsFrom(settings: nsUserDefaultSettings)
            loadBackend()
        }
    }
    @objc
    func didTapSelectPaymentMethodButton() {
        walletMode?.present(from: self)
    }

    @objc
    func didTapShippingAddressButton() {
        present(UINavigationController(rootViewController: addressViewController!), animated: true)
    }

    func updateButtons() {
        // Update the shipping address
        if let shippingAddressDetails = addressDetails {
            let shippingText = shippingAddressDetails.localizedDescription.replacingOccurrences(of: "\n", with: ", ")
            shippingAddressButton.setTitle(shippingText, for: .normal)
        } else {
            shippingAddressButton.setTitle("Add", for: .normal)
        }

        // Update the payment method selection button
        if let paymentOption = self.paymentOptionSelection {
            self.selectPaymentMethodButton.setTitle(paymentOption.displayData.label, for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.label, for: .normal)
            self.selectPaymentMethodImage.image = paymentOption.displayData.image
        } else {
            self.selectPaymentMethodButton.setTitle("Select", for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.systemBlue, for: .normal)
            self.selectPaymentMethodImage.image = nil
        }
        self.selectPaymentMethodButton.setNeedsLayout()
    }

    @IBAction func didTapEndpointConfiguration(_ sender: Any) {
        // Stubbed out for now
//        let endpointSelector = EndpointSelectorViewController(delegate: self,
//                                                              endpointSelectorEndpoint: Self.endpointSelectorEndpoint,
//                                                              currentCheckoutEndpoint: sav)
//        let navController = UINavigationController(rootViewController: endpointSelector)
//        self.navigationController?.present(navController, animated: true, completion: nil)
    }

    @IBAction func didTapResetConfig(_ sender: Any) {
        loadSettingsFrom(settings: SavedPaymentMethodSheetPlaygroundSettings.defaultValues())
    }

    @IBAction func appearanceButtonTapped(_ sender: Any) {
        if #available(iOS 14.0, *) {
            let vc = UIHostingController(rootView: AppearancePlaygroundView(appearance: appearance, doneAction: { updatedAppearance in
                self.appearance = updatedAppearance
                self.dismiss(animated: true, completion: nil)
            }))

            self.navigationController?.present(vc, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Unavailable", message: "Appearance playground is only available in iOS 14+.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Backend

extension SavedPaymentMethodSheetTestPlayground {
    @objc
    func load() {
        serializeSettingsToNSUserDefaults()
        loadBackend()
    }
    func loadBackend() {
        selectPaymentMethodButton.isEnabled = false
        shippingAddressButton.isEnabled = false
        walletMode = nil
        paymentOptionSelection = nil
        addressViewController = nil

        let customerType = customerMode == .new ? "new" : "returning"
        self.backend = WalletModeBackend(endpoint: savedPaymentMethodEndpoint)

        self.backend.loadBackendCustomerEphemeralKey(customerType: customerType) { result in
            guard let json = result else {
                print("failed to fetch backend")
                return
            }
            self.ephemeralKey = json["customerEphemeralKeySecret"]
            self.customerId = json["customerId"]
            StripeAPI.defaultPublishableKey = json["publishableKey"]

            DispatchQueue.main.async {
                guard let configuration = self.configuration else {
                    print("Failed to generate configuration")
                    return
                }
                self.walletMode = WalletMode(configuration: configuration)

                self.addressViewController = AddressViewController(configuration: self.addressConfiguration!, delegate: self)
                self.selectPaymentMethodButton.isEnabled = true
                self.shippingAddressButton.isEnabled = true

                self.walletMode?.load()
            }
        }
    }
}

extension SavedPaymentMethodSheetTestPlayground: WalletModeDelegate {
    func didError(_ error: WalletModeError) {
        switch(error) {
        case .setupIntentClientSecretInvalid:
            print("Intent invalid...")
        case .errorFetchingSavedPaymentMethods(let error):
            print("saved payment methods errored:\(error)")
        case .setupIntentFetchError(let error):
            print("fetching si errored: \(error)")
        default:
            print("something went wrong: \(error)")
        }
    }
    func didCancelWith(paymentOptionSelection: WalletMode.PaymentOptionSelection?) {
        self.paymentOptionSelection = paymentOptionSelection
        updateButtons()
    }
    func didFinishWith(paymentOptionSelection: WalletMode.PaymentOptionSelection) {
        self.paymentOptionSelection = paymentOptionSelection
        updateButtons()
    }
    func didLoadWith(paymentOptionSelection: WalletMode.PaymentOptionSelection?) {
        self.paymentOptionSelection = paymentOptionSelection
        updateButtons()
    }

}

struct SavedPaymentMethodSheetPlaygroundSettings: Codable {
    static let nsUserDefaultsKey = "savedPaymentMethodPlaygroundSettings"

    let customerModeSelectorValue: Int

    let defaultBillingAddressSelectorValue: Int
    let shippingInfoSelectorValue: Int

    let selectingSavedCustomHeaderText: String?
    let savedPaymentMethodEndpoint: String?

    static func defaultValues() -> SavedPaymentMethodSheetPlaygroundSettings {
        return SavedPaymentMethodSheetPlaygroundSettings(
            customerModeSelectorValue: 0,
            defaultBillingAddressSelectorValue: 1,
            shippingInfoSelectorValue: 0,
            selectingSavedCustomHeaderText: nil,
            savedPaymentMethodEndpoint: SavedPaymentMethodSheetTestPlayground.defaultSavedPaymentMethodEndpoint
        )
    }
}

// MARK: - AddressViewControllerDelegate
extension SavedPaymentMethodSheetTestPlayground: AddressViewControllerDelegate {
    func addressViewControllerDidFinish(_ addressViewController: AddressViewController, with address: AddressViewController.AddressDetails?) {
        addressViewController.dismiss(animated: true)
        self.addressDetails = address
        self.updateButtons()
    }
}

// MARK: - EndpointSelectorViewControllerDelegate
extension SavedPaymentMethodSheetTestPlayground: EndpointSelectorViewControllerDelegate {
    func selected(endpoint: String) {
        savedPaymentMethodEndpoint = endpoint
        serializeSettingsToNSUserDefaults()
        loadBackend()
        self.navigationController?.dismiss(animated: true)

    }
    func cancelTapped() {
        self.navigationController?.dismiss(animated: true)
    }
}

// MARK: - Helpers

extension SavedPaymentMethodSheetTestPlayground {
    func serializeSettingsToNSUserDefaults() {
        let settings = SavedPaymentMethodSheetPlaygroundSettings(
            customerModeSelectorValue: customerModeSelector.selectedSegmentIndex,
            defaultBillingAddressSelectorValue: defaultBillingAddressSelector.selectedSegmentIndex,
            shippingInfoSelectorValue: shippingInfoSelector.selectedSegmentIndex,
            selectingSavedCustomHeaderText: selectingSavedCustomHeaderTextField.text,
            savedPaymentMethodEndpoint: savedPaymentMethodEndpoint
        )
        let data = try! JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: SavedPaymentMethodSheetPlaygroundSettings.nsUserDefaultsKey)
    }

    func settingsFromDefaults() -> SavedPaymentMethodSheetPlaygroundSettings? {
        if let data = UserDefaults.standard.value(forKey: SavedPaymentMethodSheetPlaygroundSettings.nsUserDefaultsKey) as? Data {
            do {
                return try JSONDecoder().decode(SavedPaymentMethodSheetPlaygroundSettings.self, from: data)
            } catch {
                print("Unable to deserialize saved settings")
                UserDefaults.standard.removeObject(forKey: SavedPaymentMethodSheetPlaygroundSettings.nsUserDefaultsKey)
            }
        }
        return nil
    }

    func loadSettingsFrom(settings: SavedPaymentMethodSheetPlaygroundSettings) {
        customerModeSelector.selectedSegmentIndex = settings.customerModeSelectorValue

        defaultBillingAddressSelector.selectedSegmentIndex = settings.defaultBillingAddressSelectorValue
        shippingInfoSelector.selectedSegmentIndex = settings.shippingInfoSelectorValue
        selectingSavedCustomHeaderTextField.text = settings.selectingSavedCustomHeaderText
        savedPaymentMethodEndpoint = settings.savedPaymentMethodEndpoint ?? SavedPaymentMethodSheetTestPlayground.defaultSavedPaymentMethodEndpoint
    }
}


class WalletModeBackend {

    let endpoint: String
    public init(endpoint: String) {
        self.endpoint = endpoint
    }

    func loadBackendCustomerEphemeralKey(customerType: String, completion: @escaping ([String:String]?) -> Void) {

        let body = [ "customer_type": customerType
        ] as [String: Any]

        let url = URL(string: "\(endpoint)/saved_payment_method")!
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
                let json = try? JSONDecoder().decode([String: String].self, from: data) else {
                print(error as Any)
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }

    func createSetupIntent(customerId: String, completion: @escaping (String?) -> Void) {
        let body = [ "customer_id": customerId,
        ] as [String: Any]
        let url = URL(string: "\(endpoint)/create_setup_intent")!
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
                completion(nil)
                return
            }
            guard let secret = json["client_secret"] as? String else {
                completion(nil)
                return
            }
            completion(secret)
        }
        task.resume()
    }
}
