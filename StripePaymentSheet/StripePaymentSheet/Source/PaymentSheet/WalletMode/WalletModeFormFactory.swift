//
//  WalletModeFormFactory.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

class WalletModeFormFactory {

    let paymentMethod: PaymentSheet.PaymentMethodType
    let intent: Intent
    let configuration: WalletMode.Configuration
    let addressSpecProvider: AddressSpecProvider

    var theme: ElementsUITheme {
        return configuration.appearance.asElementsTheme
    }

    init(
        intent: Intent,
        configuration: WalletMode.Configuration,
        addressSpecProvider: AddressSpecProvider = .shared,
        paymentMethod: PaymentSheet.PaymentMethodType
    ) {
        self.intent = intent
        self.configuration = configuration
        self.paymentMethod = paymentMethod
        self.addressSpecProvider = addressSpecProvider
    }

    func make() -> PaymentMethodElement {
        if paymentMethod == .card {
            return makeCard(theme: theme)
        }
        assert(false, "Currently only support cards")
    }

    func makeCard(theme: ElementsUITheme = .default) -> PaymentMethodElement {
//        let saveCheckbox = makeSaveCheckbox(
//            label: String.Localized.save_this_card_for_future_$merchant_payments(
//                merchantDisplayName: configuration.merchantDisplayName
//            )
//        )
//        let shouldDisplaySaveCheckbox: Bool = saveMode == .userSelectable && !canSaveToLink
        let cardFormElement = FormElement(elements: [
            CardSection(theme: theme),
            makeBillingAddressSection(collectionMode: .countryAndPostal(),
                                      countries: nil)
            //shouldDisplaySaveCheckbox ? saveCheckbox : nil,
        ], theme: theme)
//        if isLinkEnabled {
//            return LinkEnabledPaymentMethodElement(
//                type: .card,
//                paymentMethodElement: cardFormElement,
//                configuration: configuration,
//                linkAccount: nil,
//                country: intent.countryCode
//            )
//        } else {
            return cardFormElement
//        }
    }

    func makeBillingAddressSection(
        collectionMode: AddressSectionElement.CollectionMode = .all(),
        countries: [String]?
    ) -> PaymentMethodElementWrapper<AddressSectionElement> {
        let displayBillingSameAsShippingCheckbox: Bool
        let defaultAddress: AddressSectionElement.AddressDetails
        if let shippingDetails = configuration.shippingDetails() {
            // If defaultBillingDetails and shippingDetails are both populated, prefer defaultBillingDetails
            displayBillingSameAsShippingCheckbox = configuration.defaultBillingDetails == .init()
            defaultAddress =
                displayBillingSameAsShippingCheckbox
                ? .init(shippingDetails) : configuration.defaultBillingDetails.address.addressSectionDefaults
        } else {
            displayBillingSameAsShippingCheckbox = false
            defaultAddress = configuration.defaultBillingDetails.address.addressSectionDefaults
        }

        let section = AddressSectionElement(
            title: String.Localized.billing_address_lowercase,
            countries: countries,
            addressSpecProvider: addressSpecProvider,
            defaults: defaultAddress,
            collectionMode: collectionMode,
            additionalFields: .init(
                billingSameAsShippingCheckbox: displayBillingSameAsShippingCheckbox
                    ? .enabled(isOptional: false) : .disabled
            ),
            theme: theme
        )
        return PaymentMethodElementWrapper(section) { section, params in
            guard case .valid = section.validationState else {
                return nil
            }
            if let line1 = section.line1 {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.line1 = line1.text
            }
            if let line2 = section.line2 {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.line2 = line2.text
            }
            if let city = section.city {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.city = city.text
            }
            if let state = section.state {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.state = state.rawData
            }
            if let postalCode = section.postalCode {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.postalCode = postalCode.text
            }
            params.paymentMethodParams.nonnil_billingDetails.nonnil_address.country = section.selectedCountryCode

            return params
        }
    }
}

private extension WalletMode.Address {
    var addressSectionDefaults: AddressSectionElement.AddressDetails {
        return .init(
            address: .init(
                city: city,
                country: country,
                line1: line1,
                line2: line2,
                postalCode: postalCode,
                state: state
            )
        )
    }
}
