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
    private var descriptionText = ""

    @State
    private var isButtonDisabled = true

    @State
    private var isButtonLoading: Bool? = false

    @Binding
    var isShowing: Bool

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
                                Text("Email (optional)")
                                    .font(.caption2)
                                    .padding([.leading, .trailing, .bottom], 5)
                            }

                            if WishKit.config.emailField == .required {
                                Text("Email (required)")
                                    .font(.caption2)
                                    .padding([.leading, .trailing, .bottom], 5)
                            }

                            Spacer()
                        }

                        TextField("", text: $emailText)
                            .padding(10)
                            .textFieldStyle(.plain)
                            .foregroundColor(textColor)
                            .background(fieldBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
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
                    case .createReturnedError(let errorText):
                        let button = Alert.Button.default(Text(WishKit.config.localization.ok))

                        return Alert(
                            title: Text(WishKit.config.localization.info),
                            message: Text(errorText),
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
        .ignoresSafeArea(edges: [.leading, .trailing])
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

        // Enable/Disable button
        isButtonDisabled = titleText.isEmpty || descriptionText.isEmpty
    }

    private func submitAction() {

        if WishKit.config.emailField == .required && emailText.isEmpty {
            alertModel.alertReason = .emailRequired
            alertModel.showAlert = true
            return
        }

        let isInvalidEmailFormat = (emailText.count < 6 || !emailText.contains("@") || !emailText.contains("."))
        if !emailText.isEmpty && isInvalidEmailFormat {
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
                    alertModel.alertReason = .successfullyCreated
                    alertModel.showAlert = true
                case .failure(let error):
                    alertModel.alertReason = .createReturnedError(error.reason.description)
                    alertModel.showAlert = true
                }
            }
        }
    }

    private func dismissAction() {
        self.isShowing = false
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
