//
//  BookSession.swift
//  Afable_Swift_App_ScholarLink
//
//  Created by STUDENT on 9/29/25.
//

import SwiftUI

struct BookSessionView: View {
    let tutor: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = SessionManager.shared
    @ObservedObject private var paymentStore = PaymentDetailsStore.shared
    
    @State private var selectedSubject = ""
    @State private var selectedDate = Date()
    @State private var duration = 60 // minutes
    @State private var customDurationText = ""
    @State private var message = ""
    @State private var showingConfirmation = false
    @State private var bookingMessage = ""
    @State private var showPaymentSetup = false
    
    var currentUser: User? {
        UserSession.shared.currentUser
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    tutorHeader
                    tutorPortfolioStrip
                    bookingForm
                }
                .padding()
            }
            .navigationTitle("Book Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Session Requested", isPresented: $showingConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your session request has been sent to \(tutor.firstName).")
            }
            .sheet(isPresented: $showPaymentSetup) {
                PaymentSetupView(tutor: tutor, amountDue: calculateTotalCost())
            }
        }
    }
    
    private var tutorHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("\(String(tutor.firstName.prefix(1)))\(String(tutor.lastName.prefix(1)))")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("\(tutor.firstName) \(tutor.lastName)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        if tutor.userRole == .tutor {
                            TutorVerificationBadge(status: tutor.verificationStatus)
                        }
                    }
                    
                    Text("PHP \(Int(tutor.hourlyRate ?? 0))/hour")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    if !tutor.bio.isEmpty {
                        Text(tutor.bio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                Spacer()
            }
            
            if !tutor.selectedSubjects.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tutor.selectedSubjects, id: \.self) { subject in
                            Text(subject)
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var tutorPortfolioStrip: some View {
        Group {
            if tutor.portfolioImageURLs.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tutor.portfolioImageURLs, id: \.self) { urlString in
                            if let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 140, height: 90)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 140, height: 90)
                                            .clipped()
                                            .cornerRadius(10)
                                    case .failure:
                                        Color.gray.opacity(0.2)
                                            .frame(width: 140, height: 90)
                                            .cornerRadius(10)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var bookingForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Subject
            VStack(alignment: .leading, spacing: 8) {
                Text("Subject")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Menu {
                    ForEach(tutor.selectedSubjects, id: \.self) { subject in
                        Button(subject) { selectedSubject = subject }
                    }
                } label: {
                    HStack {
                        Text(selectedSubject.isEmpty ? "Select a subject" : selectedSubject)
                            .foregroundColor(selectedSubject.isEmpty ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Date & time
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Date & Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                DatePicker("Session Date", selection: $selectedDate, in: Date()...)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Duration
            VStack(alignment: .leading, spacing: 12) {
                Text("Duration")
                    .font(.headline)
                    .fontWeight(.semibold)
                Picker("Duration", selection: $duration) {
                    Text("30 minutes").tag(30)
                    Text("60 minutes").tag(60)
                    Text("90 minutes").tag(90)
                    Text("120 minutes").tag(120)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Or enter custom minutes (e.g. 150)", text: $customDurationText)
                        .keyboardType(.numberPad)
                        .onChange(of: customDurationText) { newValue in
                            customDurationText = newValue.filter { $0.isNumber }.prefixString(maxLength: 4)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("Custom duration overrides the preset above. Minimum 30 minutes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Message
            VStack(alignment: .leading, spacing: 8) {
                Text("Message (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                TextField("Tell the tutor what you'd like to focus on...", text: $message, axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Summary
            VStack(spacing: 8) {
                HStack {
                    Text("Duration:")
                    Spacer()
                    Text("\(effectiveDuration) minutes")
                }
                HStack {
                    Text("Rate:")
                    Spacer()
                    Text("PHP \(Int(tutor.hourlyRate ?? 0))/hour")
                }
                Divider()
                HStack {
                    Text("Total Cost:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("PHP \(Int(calculateTotalCost()))")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
            
            PaymentMethodStatusCard(
                details: paymentStore.savedDetails,
                tutor: tutor,
                amountDue: calculateTotalCost(),
                action: { showPaymentSetup = true }
            )
            
            Button(action: bookSession) {
                Text("Request Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canRequestSession ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!canRequestSession)
            
            Text(bookingMessage)
                .foregroundColor(bookingMessage.contains("Success") ? .green : .red)
                .font(.caption)
            
            if !selectedSubject.isEmpty && paymentStore.savedDetails == nil {
                Text("Add a payment method to finish your booking.")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }
    
    private var canRequestSession: Bool {
        !selectedSubject.isEmpty && paymentStore.savedDetails != nil
    }
    
    private var effectiveDuration: Int {
        if let custom = Int(customDurationText), custom >= 30 {
            return custom
        }
        return duration
    }
    
    private func calculateTotalCost() -> Double {
        let hourlyRate = tutor.hourlyRate ?? 0
        let hours = Double(effectiveDuration) / 60.0
        return hourlyRate * hours
    }
    
    private func bookSession() {
        guard let student = currentUser else {
            bookingMessage = "Error: No student account found"
            return
        }
        guard !selectedSubject.isEmpty else {
            bookingMessage = "Please select a subject"
            return
        }
        let actualDuration = effectiveDuration
        Task {
            do {
                try await sessionManager.addSession(
                    studentId: student.id,
                    tutorId: tutor.id,
                    studentName: "\(student.firstName) \(student.lastName)",
                    studentEmail: student.email,
                    tutorName: "\(tutor.firstName) \(tutor.lastName)",
                    tutorEmail: tutor.email,
                    subject: selectedSubject,
                    date: selectedDate,
                    duration: actualDuration,
                    message: message,
                    hourlyRate: tutor.hourlyRate ?? 0
                )
                await MainActor.run {
                    bookingMessage = "Success! Session request sent to \(tutor.firstName)"
                    showingConfirmation = true
                }
            } catch {
                await MainActor.run {
                    bookingMessage = "Failed to book session. Please try again."
                }
            }
        }
    }
}

private extension String {
    func prefixString(maxLength: Int) -> String {
        String(prefix(maxLength))
    }
}

struct BookSessionView_Previews: PreviewProvider {
    static var previews: some View {
        Text("BookSessionView Preview")
    }
}
