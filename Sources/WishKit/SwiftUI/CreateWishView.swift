//
//  CreateWishView.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 8/26/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

import SwiftUI
import Combine
import WishKitShared

struct CreateWishView: View {

    @Environment(\.presentationMode) var presentationMode

    @Environment(\.colorScheme)
    private var colorScheme

    @ObservedObject
    private var alertModel = AlertModel()

    @State
    private var titleCharCount = 0

    @State
    private var titleText = ""

    @State
    private var emailText = ""

    @State
    private var isEmailValid = true

    @State
    private var descriptionText = ""

    @State
    private var isButtonDisabled = true

    @State
    private var isButtonLoading: Bool? = false

    let createActionCompletion: () -> Void

    var saveButtonSize: CGSize {
        #if os(macOS)
            return CGSize(width: 100, height: 30)
        #else
            return CGSize(width: 200, height: 45)
        #endif
    }

    var body: some View {
        ScrollView {
            Spacer(minLength: 15)

            VStack(spacing: 15) {
                VStack(spacing: 0) {
                    HStack {
                        Text(WishKit.config.localization.title)
                        Spacer()
                        Text("\(titleText.count)/50")
                    }
                    .font(.caption2)
                    .padding([.leading, .trailing, .bottom], 5)

                    TextField("", text: $titleText)
                        .padding(10)
                        .textFieldStyle(.plain)
                        .foregroundColor(textColor)
                        .background(fieldBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
                        .onReceive(Just(titleText)) { _ in handleTitleAndDescriptionChange() }
                }

                VStack(spacing: 0) {
                    HStack {
                        Text(WishKit.config.localization.description)
                        Spacer()
                        Text("\(descriptionText.count)/500")
                    }
                    .font(.caption2)
                    .padding([.leading, .trailing, .bottom], 5)

                    TextEditor(text: $descriptionText)
                        .padding([.leading, .trailing], 5)
                        .padding([.top, .bottom], 10)
                        .lineSpacing(3)
                        .frame(height: 200)
                        .foregroundColor(textColor)
                        .scrollContentBackgroundCompat(.hidden)
                        .background(fieldBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
                        .onReceive(Just(descriptionText)) { _ in handleTitleAndDescriptionChange() }
                }

                if WishKit.config.emailField != .none {
                    VStack(spacing: 0) {
                        HStack {
                            if WishKit.config.emailField == .optional {
                                Text(WishKit.config.localization.emailOptional)
                                    .font(.caption2)
                                    .padding([.leading, .trailing, .bottom], 5)
                            }

                            if WishKit.config.emailField == .required {
                                Text(WishKit.config.localization.emailRequired)
                                    .font(.caption2)
                                    .padding([.leading, .trailing, .bottom], 5)
                            }
                            Spacer()
                        }

                        TextField("", text: $emailText)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(10)
                            .textFieldStyle(.plain)
                            .foregroundColor(textColor)
                            .background(fieldBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
                            .onChange(of: emailText) { _ in handleEmailChange() }

                        if !self.isEmailValid {
                            Text(WishKit.config.localization.emailFormatWrongText)
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding([.leading, .trailing, .bottom], 5)
                        }
                    }
                }

                #if os(macOS)
                    Spacer()
                #endif

                WKButton(
                    text: WishKit.config.localization.save,
                    action: submitAction,
                    style: .primary,
                    isLoading: $isButtonLoading,
                    size: saveButtonSize
                )
                .disabled(isButtonDisabled)
                .alert(isPresented: $alertModel.showAlert) {

                    switch alertModel.alertReason {
                    case .successfullyCreated:
                        let button = Alert.Button.default(
                            Text(WishKit.config.localization.ok),
                            action: {
                                createActionCompletion()
                                dismissAction()
                            }
                        )

                        return Alert(
                            title: Text(WishKit.config.localization.info),
                            message: Text(WishKit.config.localization.successfullyCreated),
                            dismissButton: button
                        )
                    case .createReturnedError(_):
                        let button = Alert.Button.default(Text(WishKit.config.localization.ok))

                        return Alert(
                            title: Text(WishKit.config.localization.info),
                            message: Text(WishKit.config.localization.wishSubmitErrorAlert),
                            dismissButton: button
                        )
                    case .emailRequired:
                        let button = Alert.Button.default(Text(WishKit.config.localization.ok))

                        return Alert(
                            title: Text(WishKit.config.localization.info),
                            message: Text(WishKit.config.localization.emailRequiredText),
                            dismissButton: button
                        )
                    case .emailFormatWrong:
                        let button = Alert.Button.default(Text(WishKit.config.localization.ok))

                        return Alert(
                            title: Text(WishKit.config.localization.info),
                            message: Text(WishKit.config.localization.emailFormatWrongText),
                            dismissButton: button
                        )
                    case .none:
                        let button = Alert.Button.default(Text(WishKit.config.localization.ok))
                        return Alert(title: Text(""), dismissButton: button)
                    default:
                        let button = Alert.Button.default(Text(WishKit.config.localization.ok))
                        return Alert(title: Text(""), dismissButton: button)
                    }

                }
            }
            .frame(maxWidth: 700)
            .padding()

            #if os(iOS)
                Spacer()
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .ignoresSafeArea(.container, edges: [.leading, .bottom, .trailing])
        .toolbarKeyboardDoneButton()
    }

    private func handleTitleAndDescriptionChange() {

        // Keep characters within limits
        let titleLimit = 50
        let descriptionLimit = 500
        
        if titleText.count > titleLimit {
            titleText = String(titleText.prefix(titleLimit))
        }

        if descriptionText.count > descriptionLimit {
            descriptionText = String(descriptionText.prefix(descriptionLimit))
        }

        self.checkButtonStatus()
    }

    private func handleEmailChange() {
        guard !self.emailText.isEmpty else { return }

        // Perform email address validation by using Foundation’s NSDataDetector API.
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(
            self.emailText.startIndex..<self.emailText.endIndex,
            in: self.emailText
        )
        let matches = detector?.matches(in: self.emailText, options: [], range: range)

        // We only want our string to contain a single email address, so if multiple matches were found, then we fail our validation process.
        // Verify that the found link points to an email address, and that its range covers the whole input string:
        guard let match = matches?.first,
              matches?.count == 1,
              match.url?.scheme == "mailto",
              match.range == range
        else {
            self.isEmailValid = false
            return
        }
        self.isEmailValid = true
    }

    /// Enable/Disable submit button
    private func checkButtonStatus() {
        let emailIsNotValid = WishKit.config.emailField == .required && (emailText.isEmptyOrOnlySpaces || !isEmailValid)
        isButtonDisabled = titleText.isEmptyOrOnlySpaces || descriptionText.isEmptyOrOnlySpaces || emailIsNotValid
    }

    private func submitAction() {

        if WishKit.config.emailField == .required && emailText.isEmptyOrOnlySpaces {
            alertModel.alertReason = .emailRequired
            alertModel.showAlert = true
            return
        }

        let isInvalidEmailFormat = (emailText.count < 6 || !emailText.contains("@") || !emailText.contains("."))
        if !emailText.isEmptyOrOnlySpaces && isInvalidEmailFormat {
            alertModel.alertReason = .emailFormatWrong
            alertModel.showAlert = true
            return
        }

        isButtonLoading = true

        let createRequest = CreateWishRequest(title: titleText, description: descriptionText, email: emailText)
        WishApi.createWish(createRequest: createRequest) { result in
            isButtonLoading = false
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Instead of showing an alert, we propagate the event and let the application handle it itself.
                    createActionCompletion()
                    dismissAction()
                    // alertModel.alertReason = .successfullyCreated
                    // alertModel.showAlert = true
                case .failure(let error):
                    alertModel.alertReason = .createReturnedError(error.reason.description)
                    alertModel.showAlert = true
                }
            }
        }
    }

    private func dismissAction() {
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Color Scheme

extension CreateWishView {

    var textColor: Color {
        switch colorScheme {
        case .light:

            if let color = WishKit.theme.textColor {
                return color.light
            }

            return .black
        case .dark:
            if let color = WishKit.theme.textColor {
                return color.dark
            }

            return .white
        }
    }

    var backgroundColor: Color {
        switch colorScheme {
        case .light:
            if let color = WishKit.theme.tertiaryColor {
                return color.light
            }

            return PrivateTheme.systemBackgroundColor.light
        case .dark:
            if let color = WishKit.theme.tertiaryColor {
                return color.dark
            }

            return PrivateTheme.systemBackgroundColor.dark
        @unknown default:
            if let color = WishKit.theme.tertiaryColor {
                return color.light
            }

            return PrivateTheme.systemBackgroundColor.light
        }
    }

    var fieldBackgroundColor: Color {
        switch colorScheme {
        case .light:
            if let color = WishKit.theme.secondaryColor {
                return color.light
            }

            return PrivateTheme.elementBackgroundColor.light
        case .dark:
            if let color = WishKit.theme.secondaryColor {
                return color.dark
            }

            return PrivateTheme.elementBackgroundColor.dark
        @unknown default:
            if let color = WishKit.theme.tertiaryColor {
                return color.light
            }

            return PrivateTheme.systemBackgroundColor.light
        }
    }
}

extension String {
    var isEmptyOrOnlySpaces: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
