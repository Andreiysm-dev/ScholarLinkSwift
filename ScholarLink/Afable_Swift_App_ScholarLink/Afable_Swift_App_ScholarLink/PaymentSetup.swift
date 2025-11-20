//
//  PaymentSetup.swift
//  Afable_Swift_App_ScholarLink
//
//  Created by ChatGPT on 11/18/25.
//

import SwiftUI

struct PaymentDetails: Codable, Equatable {
    var cardholderName: String = ""
    var cardNumber: String = ""
    var expiryMonth: String = ""
    var expiryYear: String = ""
    var cvv: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var billingAddress: BillingAddress = .init()
    var saveForFutureSessions: Bool = true
    var enableAutoApproval: Bool = false
    
    var maskedCardNumber: String {
        let last4 = cardNumber.suffix(4)
        return "•••• •••• •••• \(String(last4))"
    }
    
    var formattedCardNumber: String {
        cardNumber.grouped(by: 4, separator: " ")
    }
    
    var expirationDisplay: String {
        guard !expiryMonth.isEmpty, !expiryYear.isEmpty else { return "" }
        return "\(expiryMonth)/\(expiryYear.suffix(2))"
    }
}

struct BillingAddress: Codable, Equatable {
    var street: String = ""
    var city: String = ""
    var province: String = ""
    var postalCode: String = ""
    var country: String = "Philippines"
    
    var isComplete: Bool {
        !street.isEmpty && !city.isEmpty && !province.isEmpty && !postalCode.isEmpty
    }
}

@MainActor
final class PaymentDetailsStore: ObservableObject {
    static let shared = PaymentDetailsStore()
    
    @Published private(set) var savedDetails: PaymentDetails?
    @Published private(set) var lastUpdated: Date?
    
    private static let storageKey = "scholarlink.payment.details"
    private static let timestampKey = "scholarlink.payment.details.updated_at"
    
    private init() {
        savedDetails = Self.loadFromDisk()
        lastUpdated = UserDefaults.standard.object(forKey: Self.timestampKey) as? Date
    }
    
    func save(_ details: PaymentDetails) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(details)
        let now = Date()
        
        UserDefaults.standard.set(data, forKey: Self.storageKey)
        UserDefaults.standard.set(now, forKey: Self.timestampKey)
        savedDetails = details
        lastUpdated = now
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        UserDefaults.standard.removeObject(forKey: Self.timestampKey)
        savedDetails = nil
        lastUpdated = nil
    }
    
    static func hasStoredDetails() -> Bool {
        loadFromDisk() != nil
    }
    
    private static func loadFromDisk() -> PaymentDetails? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(PaymentDetails.self, from: data)
    }
}

struct PaymentSetupView: View {
    let tutor: User
    let amountDue: Double
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = PaymentDetailsStore.shared
    
    @State private var cardholderName = ""
    @State private var cardNumber = ""
    @State private var expiration = ""
    @State private var cvv = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var street = ""
    @State private var city = ""
    @State private var province = ""
    @State private var postalCode = ""
    @State private var country = "Philippines"
    @State private var saveForFutureSessions = true
    @State private var autoApprovePayments = false
    
    @State private var statusMessage = ""
    @State private var isSaving = false
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case cardholder, cardNumber, expiration, cvv, email, phone, street, city, province, postalCode
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PaymentSummaryCard(tutor: tutor, amountDue: amountDue, details: store.savedDetails, lastUpdated: store.lastUpdated)
                    
                    paymentMethodSection
                    
                    billingSection
                    
                    preferencesSection
                    
                    Button(action: save) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "Saving..." : "Save Payment Method")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canSave || isSaving)
                    
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundColor(statusMessage.contains("saved") ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Payment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: prefillFields)
        }
    }
    
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("Name on card", text: $cardholderName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .cardholder)
                    .submitLabel(.next)
                    .modifier(PaymentFieldStyle(icon: "person"))
                
                TextField("Card number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .cardNumber)
                    .onChange(of: cardNumber) { newValue in
                        cardNumber = newValue.formattedCardNumber(maxLength: 16)
                    }
                    .modifier(PaymentFieldStyle(icon: "creditcard"))
                
                HStack(spacing: 12) {
                    TextField("MM/YY", text: $expiration)
                        .keyboardType(.numbersAndPunctuation)
                        .focused($focusedField, equals: .expiration)
                        .onChange(of: expiration) { newValue in
                            expiration = newValue.formattedExpiration()
                        }
                        .modifier(PaymentFieldStyle(icon: "calendar"))
                    
                    SecureField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .cvv)
                        .onChange(of: cvv) { newValue in
                            cvv = String(newValue.filter(\.isNumber).prefix(4))
                        }
                        .modifier(PaymentFieldStyle(icon: "lock"))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
    }
    
    private var billingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("Email for receipts", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .modifier(PaymentFieldStyle(icon: "envelope"))
                
                TextField("Mobile number", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .phone)
                    .onChange(of: phoneNumber) { newValue in
                        phoneNumber = newValue.formattedPhone()
                    }
                    .modifier(PaymentFieldStyle(icon: "phone"))
                
                TextField("Street address", text: $street)
                    .textContentType(.streetAddressLine1)
                    .focused($focusedField, equals: .street)
                    .modifier(PaymentFieldStyle(icon: "mappin.and.ellipse"))
                
                HStack(spacing: 12) {
                    TextField("City", text: $city)
                        .textContentType(.addressCity)
                        .focused($focusedField, equals: .city)
                        .modifier(PaymentFieldStyle(icon: "building"))
                    
                    TextField("Province", text: $province)
                        .textContentType(.addressState)
                        .focused($focusedField, equals: .province)
                        .modifier(PaymentFieldStyle(icon: "map"))
                }
                
                HStack(spacing: 12) {
                    TextField("Postal code", text: $postalCode)
                        .keyboardType(.numbersAndPunctuation)
                        .focused($focusedField, equals: .postalCode)
                        .modifier(PaymentFieldStyle(icon: "number"))
                    
                    TextField("Country", text: $country)
                        .textContentType(.countryName)
                        .modifier(PaymentFieldStyle(icon: "globe.asia.australia"))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.headline)
            
            Toggle(isOn: $saveForFutureSessions) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save for future bookings")
                    Text("Securely store this method for upcoming tutor sessions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $autoApprovePayments) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-approve tutor payouts")
                    Text("Automatically release payments once a tutor confirms completion.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    private var canSave: Bool {
        let hasCard = cardholderName.count >= 3 && cardNumber.digitsOnly.count >= 12
        let expiryParts = expirationComponents
        let hasExpiry = !expiryParts.month.isEmpty && !expiryParts.year.isEmpty
        let hasCVV = cvv.count >= 3
        let hasBilling = !email.isEmpty && !street.isEmpty && !city.isEmpty && !province.isEmpty && !postalCode.isEmpty
        return hasCard && hasExpiry && hasCVV && hasBilling && !email.isEmpty
    }
    
    private var expirationComponents: (month: String, year: String) {
        let digits = expiration.digitsOnly
        let month = String(digits.prefix(2))
        let year = digits.count >= 4 ? String(digits.dropFirst(2).prefix(2)) : ""
        return (month, year)
    }
    
    private func prefillFields() {
        guard let details = store.savedDetails else { return }
        cardholderName = details.cardholderName
        cardNumber = details.formattedCardNumber
        expiration = details.expirationDisplay
        cvv = details.cvv
        phoneNumber = details.phoneNumber.formattedPhone()
        email = details.email
        street = details.billingAddress.street
        city = details.billingAddress.city
        province = details.billingAddress.province
        postalCode = details.billingAddress.postalCode
        country = details.billingAddress.country
        saveForFutureSessions = details.saveForFutureSessions
        autoApprovePayments = details.enableAutoApproval
    }
    
    private func save() {
        guard canSave else {
            statusMessage = "Complete all required fields"
            return
        }
        
        isSaving = true
        statusMessage = ""
        
        let parts = expirationComponents
        let sanitizedDetails = PaymentDetails(
            cardholderName: cardholderName.trimmingCharacters(in: .whitespaces),
            cardNumber: cardNumber.digitsOnly,
            expiryMonth: parts.month,
            expiryYear: parts.year,
            cvv: cvv,
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            billingAddress: BillingAddress(
                street: street.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces),
                province: province.trimmingCharacters(in: .whitespaces),
                postalCode: postalCode.trimmingCharacters(in: .whitespaces),
                country: country.trimmingCharacters(in: .whitespaces).isEmpty ? "Philippines" : country
            ),
            saveForFutureSessions: saveForFutureSessions,
            enableAutoApproval: autoApprovePayments
        )
        
        Task {
            defer { isSaving = false }
            do {
                try store.save(sanitizedDetails)
                statusMessage = "Payment method saved"
                dismiss()
            } catch {
                statusMessage = "Unable to save payment method. Please try again."
            }
        }
    }
}

struct PaymentSummaryCard: View {
    let tutor: User
    let amountDue: Double
    let details: PaymentDetails?
    let lastUpdated: Date?
    
    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tutor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(tutor.firstName) \(tutor.lastName)")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Amount due")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatter.string(from: NSNumber(value: amountDue)) ?? "PHP \(amountDue)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment method")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let details {
                        Text(details.maskedCardNumber)
                            .font(.subheadline)
                        if let lastUpdated {
                            Text("Updated \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not configured")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                Spacer()
                Image(systemName: details == nil ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .foregroundColor(details == nil ? .orange : .green)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.07))
        .cornerRadius(14)
    }
}

struct PaymentMethodStatusCard: View {
    let details: PaymentDetails?
    let tutor: User
    let amountDue: Double
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment method")
                        .font(.headline)
                    Text(details?.maskedCardNumber ?? "Add a payment method to continue")
                        .font(.subheadline)
                        .foregroundColor(details == nil ? .orange : .secondary)
                }
                Spacer()
                Button(action: action) {
                    Text(details == nil ? "Set Up" : "Manage")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(10)
                }
            }
            
            HStack {
                Text("Estimated total:")
                Spacer()
                Text("PHP \(Int(amountDue))")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}

private struct PaymentFieldStyle: ViewModifier {
    let icon: String
    
    func body(content: Content) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            content
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

private extension String {
    var digitsOnly: String {
        filter(\.isNumber)
    }
    
    func grouped(by groupSize: Int, separator: String) -> String {
        let digits = digitsOnly
        return stride(from: 0, to: digits.count, by: groupSize).map { index in
            let startIndex = digits.index(digits.startIndex, offsetBy: index)
            let endIndex = digits.index(startIndex, offsetBy: groupSize, limitedBy: digits.endIndex) ?? digits.endIndex
            return String(digits[startIndex..<endIndex])
        }
        .joined(separator: separator)
    }
    
    func formattedCardNumber(maxLength: Int) -> String {
        let digits = digitsOnly.prefix(maxLength)
        return String(digits).grouped(by: 4, separator: " ")
    }
    
    func formattedExpiration() -> String {
        let digits = digitsOnly.prefix(4)
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 2 { result.append("/") }
            result.append(char)
        }
        return result
    }
    
    func formattedPhone() -> String {
        let digits = digitsOnly.prefix(11)
        guard !digits.isEmpty else { return "" }
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 4 || index == 7 {
                result.append(" ")
            }
            result.append(char)
        }
        return result
    }
}

