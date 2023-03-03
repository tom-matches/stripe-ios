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
    // Inline
    @IBOutlet weak var selectPaymentMethodImage: UIImageView!
    @IBOutlet weak var selectPaymentMethodButton: UIButton!
    @IBOutlet weak var shippingAddressButton: UIButton!
   // @IBOutlet weak var checkoutInlineButton: UIButton!
    // Complete
    //@IBOutlet weak var checkoutButton: UIButton!

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
        if let customerID = customerID,
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
        guard let customerConfiguration = customerConfiguration else {
            return nil
        }
        var configuration = WalletMode.Configuration(customer: customerConfiguration,
                                                     createSetupIntentHandler: { completionBlock in
            self.backend.createSetupIntent(completion: completionBlock)
        })

        configuration.customer = customerConfiguration
        configuration.appearance = appearance

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
    var customerID: String?
    var savedPaymentMethodEndpoint: String = defaultSavedPaymentMethodEndpoint
    var paymentSheetFlowController: PaymentSheet.FlowController?
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
/*
    @objc
    func didTapCheckoutInlineButton() {
        checkoutInlineButton.isEnabled = false
        paymentSheetFlowController?.confirm(from: self) { result in
            let alertController = self.makeAlertController()
            switch result {
            case .canceled:
                alertController.message = "canceled"
                self.checkoutInlineButton.isEnabled = true
            case .failed(let error):
                alertController.message = "\(error)"
                self.present(alertController, animated: true)
                self.checkoutInlineButton.isEnabled = true
            case .completed:
                alertController.message = "Success!"
                self.present(alertController, animated: true)
            }
        }
    }*/
    /*

    @objc
    func didTapCheckoutButton() {
        let mc: PaymentSheet
        switch intentMode {
        case .payment, .paymentWithSetup:
            mc = PaymentSheet(paymentIntentClientSecret: clientSecret!, configuration: configuration)
        case .setup:
            mc = PaymentSheet(setupIntentClientSecret: clientSecret!, configuration: configuration)
        }
        mc.present(from: self) { result in
            let alertController = self.makeAlertController()
            switch result {
            case .canceled:
                print("Canceled! \(String(describing: mc.mostRecentError))")
            case .failed(let error):
                alertController.message = error.localizedDescription
                print(error)
                self.present(alertController, animated: true)
            case .completed:
                alertController.message = "Success!"
                self.present(alertController, animated: true)
                self.checkoutButton.isEnabled = false
            }
        }
    }*/

    @IBAction func didtapWalletMode(_ sender: Any) {
        presentWalletMode()
    }
    @objc
    func didTapSelectPaymentMethodButton() {
        paymentSheetFlowController?.presentPaymentOptions(from: self) {
            self.updateButtons()
        }
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
        if let paymentOption = paymentSheetFlowController?.paymentOption {
            self.selectPaymentMethodButton.setTitle(paymentOption.label, for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.label, for: .normal)
            self.selectPaymentMethodImage.image = paymentOption.image
//            self.checkoutInlineButton.isEnabled = true
        } else {
            self.selectPaymentMethodButton.setTitle("Select", for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.systemBlue, for: .normal)
            self.selectPaymentMethodImage.image = nil
//            self.checkoutInlineButton.isEnabled = false
        }
        self.selectPaymentMethodButton.setNeedsLayout()
    }

    @IBAction func didTapEndpointConfiguration(_ sender: Any) {
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
        //checkoutButton.isEnabled = false
//        checkoutInlineButton.isEnabled = false
        selectPaymentMethodButton.isEnabled = false
        shippingAddressButton.isEnabled = false
        paymentSheetFlowController = nil
        addressViewController = nil

        let customerType = customerMode == .new ? "new" : "returning"
        self.backend = WalletModeBackend(endpoint: savedPaymentMethodEndpoint,
                                         customerType: customerType)
        self.backend.loadBackendCustomerEphemeralKey { result in
            guard let json = result else {
                print("failed to fetch backend")
                return
            }
            self.ephemeralKey = json["customerEphemeralKeySecret"]
            self.customerID = json["customerId"]
            StripeAPI.defaultPublishableKey = json["publishableKey"]
            DispatchQueue.main.async {
                self.addressViewController = AddressViewController(configuration: self.addressConfiguration!, delegate: self)
                //self.checkoutButton.isEnabled = true
//                self.checkoutInlineButton.isEnabled = true
                self.selectPaymentMethodButton.isEnabled = true
                self.shippingAddressButton.isEnabled = true
            }
        }
    }
    func presentWalletMode() {
        guard let ephemeralKey = ephemeralKey,
              let customerID = customerID else {
            return
        }
        let customerConfig = WalletMode.CustomerConfiguration(id: customerID,
                                                              ephemeralKeySecret: ephemeralKey)
        var configuration = WalletMode.Configuration(
            customer: customerConfig,
            createSetupIntentHandler: { completionBlock in
                self.backend.createSetupIntent(completion: completionBlock)
            },
            delegate: self)

        configuration.selectingSavedCustomHeaderText = "Update your payment method"
        let walletMode = WalletMode(configuration: configuration)
        DispatchQueue.main.async {
            walletMode.present(from: self)
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
        print("cancel with: \(paymentOptionSelection?.paymentMethodId)")
        print("\(paymentOptionSelection?.displayData.label)")
        print("\(paymentOptionSelection?.displayData.image)")
    }
    func didFinishWith(paymentOptionSelection: WalletMode.PaymentOptionSelection) {
        print("finish with: \(paymentOptionSelection.paymentMethodId)")
        print("\(paymentOptionSelection.displayData.label)")
        print("\(paymentOptionSelection.displayData.image)")

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

    let customerType: String
    let endpoint: String

    var customerId: String?
    var customerEphemeralKey: String?
    public init(endpoint: String,
                customerType: String) {
        self.customerType = customerType
        self.endpoint = endpoint
    }

    func loadBackendCustomerEphemeralKey(completion: @escaping ([String:String]?) -> Void) {

        let body = [ "customer_type": self.customerType
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
    func createSetupIntent(completion: @escaping (String?) -> Void) {
        let body = [ "customer_id": self.customerId,
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
